import Foundation

/// Custom errors for API operations
enum APIError: Error, LocalizedError {
    case badURL
    case badServerResponse
    case unauthorized
    case tokenExpired
    case refreshFailed
    case httpError(statusCode: Int, message: String)
    
    var errorDescription: String? {
        switch self {
        case .badURL:
            return "Invalid URL"
        case .badServerResponse:
            return "Bad server response"
        case .unauthorized:
            return "Authentication required"
        case .tokenExpired:
            return "Session expired"
        case .refreshFailed:
            return "Failed to refresh session. Please log in again."
        case .httpError(let code, let message):
            return "HTTP \(code): \(message)"
        }
    }
}

/// Delegate protocol for handling authentication state changes
protocol APIClientDelegate: AnyObject {
    func apiClientDidRequireReauthentication()
}

class APIClient {
    static let shared = APIClient()
    
    private let session: URLSession
    private let baseURL: String = AppConfig.apiBaseURL
    
    private var accessToken: String?
    private var isRefreshing = false
    private var pendingRequests: [(CheckedContinuation<Void, Error>)] = []
    
    weak var delegate: APIClientDelegate?
    
    init() {
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config)
    }
    
    func setAccessToken(_ token: String?) {
        self.accessToken = token
    }
    
    func getAccessToken() -> String? {
        return accessToken
    }
    
    func clearAccessToken() {
        self.accessToken = nil
    }
    
    /// Makes an authenticated request with automatic token refresh on 401/403
    func request<T: Codable>(_ endpoint: String, method: String = "GET", body: Encodable? = nil, requiresAuth: Bool = true) async throws -> T {
        return try await performRequest(endpoint, method: method, body: body, requiresAuth: requiresAuth, isRetry: false)
    }
    
    private func performRequest<T: Codable>(_ endpoint: String, method: String, body: Encodable?, requiresAuth: Bool, isRetry: Bool) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.badURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if requiresAuth, let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.badServerResponse
        }
        
        // Handle 401 (Unauthorized) or 403 (Forbidden) - try to refresh token
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            if requiresAuth && !isRetry {
                // Try to refresh the token
                let refreshed = await refreshAccessToken()
                if refreshed {
                    // Retry the original request with new token
                    return try await performRequest(endpoint, method: method, body: body, requiresAuth: requiresAuth, isRetry: true)
                } else {
                    // Refresh failed - notify delegate to trigger re-authentication
                    await MainActor.run {
                        delegate?.apiClientDidRequireReauthentication()
                    }
                    throw APIError.refreshFailed
                }
            } else {
                throw APIError.unauthorized
            }
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let serverMessage = String(data: data, encoding: .utf8) ?? ""
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: serverMessage)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(T.self, from: data)
    }
    
    /// Attempts to refresh the access token using the stored refresh token
    private func refreshAccessToken() async -> Bool {
        // Prevent multiple simultaneous refresh attempts
        guard !isRefreshing else {
            // Wait for ongoing refresh to complete
            return await withCheckedContinuation { continuation in
                // This is a simplified wait - in production you'd want a proper queue
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    continuation.resume(returning: accessToken != nil)
                }
            }
        }
        
        isRefreshing = true
        defer { isRefreshing = false }
        
        do {
            let refreshToken = try KeychainManager.retrieveRefreshToken()
            
            guard let url = URL(string: baseURL + "/api/v1/auth/refresh") else {
                return false
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            // Send refresh token as cookie (matching backend expectation)
            request.setValue("refresh_token=\(refreshToken)", forHTTPHeaderField: "Cookie")
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                // Refresh token is invalid - clear stored tokens
                try? KeychainManager.clearTokens()
                accessToken = nil
                return false
            }
            
            let decoder = JSONDecoder()
            let refreshResponse = try decoder.decode(RefreshResponse.self, from: data)
            
            // Store new tokens
            accessToken = refreshResponse.accessToken
            try KeychainManager.storeRefreshToken(refreshResponse.refreshToken)
            
            return true
            
        } catch {
            print("Token refresh failed: \(error)")
            return false
        }
    }
    
    /// Makes a request without authentication (for login flow)
    func unauthenticatedRequest<T: Codable>(_ endpoint: String, method: String = "GET", body: Encodable? = nil) async throws -> T {
        return try await performRequest(endpoint, method: method, body: body, requiresAuth: false, isRetry: true)
    }
    
    // MARK: - Multipart Form Data Upload
    
    /// Uploads a file with multipart/form-data (for document creation)
    func uploadMultipart<T: Codable>(
        _ endpoint: String,
        fileData: Data,
        fileName: String,
        mimeType: String = "application/pdf",
        formFields: [String: String]
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.badURL
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Build multipart body
        var body = Data()
        
        // Add form fields
        for (key, value) in formFields {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // Add file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.badServerResponse
        }
        
        // Handle 401/403 - try to refresh and retry
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            let refreshed = await refreshAccessToken()
            if refreshed {
                // Retry with new token
                return try await uploadMultipart(endpoint, fileData: fileData, fileName: fileName, mimeType: mimeType, formFields: formFields)
            } else {
                await MainActor.run {
                    delegate?.apiClientDidRequireReauthentication()
                }
                throw APIError.refreshFailed
            }
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let serverMessage = String(data: data, encoding: .utf8) ?? ""
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: serverMessage)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(T.self, from: data)
    }
    
    /// Uploads a file with multipart/form-data without authentication (for document verification)
    func uploadMultipartPublic<T: Codable>(
        _ endpoint: String,
        fileData: Data,
        fileName: String,
        mimeType: String = "application/pdf"
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.badURL
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Build multipart body (file only, no form fields needed for verification)
        var body = Data()
        
        // Add file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.badServerResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let serverMessage = String(data: data, encoding: .utf8) ?? ""
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: serverMessage)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(T.self, from: data)
    }
    
    // MARK: - File Download
    
    /// Downloads a file (PDF) from the given endpoint
    func downloadFile(_ endpoint: String) async throws -> Data {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.badURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.badServerResponse
        }
        
        // Handle 401/403 - try to refresh and retry
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            let refreshed = await refreshAccessToken()
            if refreshed {
                return try await downloadFile(endpoint)
            } else {
                await MainActor.run {
                    delegate?.apiClientDidRequireReauthentication()
                }
                throw APIError.refreshFailed
            }
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let serverMessage = String(data: data, encoding: .utf8) ?? ""
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: serverMessage)
        }
        
        return data
    }
}
