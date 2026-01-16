import Foundation
import SwiftUI
internal import Combine

/// ViewModel for managing the multi-step registration flow
@MainActor
class RegistrationViewModel: ObservableObject {
    // MARK: - Published State
    
    @Published var email: String = ""
    @Published var otpCode: String = ""
    @Published var fullName: String = ""
    @Published var username: String = ""
    @Published var phone: String = ""
    @Published var idnp: String = ""
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Navigation state
    @Published var currentStep: RegistrationStep = .email
    @Published var requestId: String?
    
    enum RegistrationStep {
        case email
        case otp
        case details
        case pending
    }
    
    // MARK: - Validation
    
    var isEmailValid: Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
    
    var isOTPValid: Bool {
        otpCode.count == 6 && otpCode.allSatisfy { $0.isNumber }
    }
    
    var isDetailsValid: Bool {
        !fullName.isEmpty &&
        fullName.count <= 120 &&
        username.count >= 3 &&
        username.count <= 50 &&
        username.range(of: #"^[a-zA-Z0-9._-]+$"#, options: .regularExpression) != nil &&
        phone.count >= 5 &&
        phone.count <= 20 &&
        idnp.count >= 5 &&
        idnp.count <= 20
    }
    
    // MARK: - API Calls
    
    /// Step 1: Request OTP for email verification
    func requestOTP() async {
        guard isEmailValid else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let url = URL(string: "\(AppConfig.apiBaseURL)/api/v1/registration/request/start")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body = ["email": email]
            request.httpBody = try JSONEncoder().encode(body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw RegistrationError.badResponse
            }
            
            if httpResponse.statusCode == 200 {
                currentStep = .otp
            } else if httpResponse.statusCode == 409 {
                errorMessage = "This email is already registered"
            } else {
                let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                errorMessage = errorResponse?.error ?? "Failed to send verification code"
            }
        } catch {
            errorMessage = "Network error: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Step 2: Verify OTP code
    func verifyOTP() async {
        guard isOTPValid else {
            errorMessage = "Please enter a valid 6-digit code"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let url = URL(string: "\(AppConfig.apiBaseURL)/api/v1/registration/request/verify")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body = ["email": email, "code": otpCode]
            request.httpBody = try JSONEncoder().encode(body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw RegistrationError.badResponse
            }
            
            if httpResponse.statusCode == 200 {
                currentStep = .details
            } else {
                let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                errorMessage = errorResponse?.error ?? "Invalid verification code"
            }
        } catch {
            errorMessage = "Network error: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Step 3: Submit registration request
    func submitRequest() async {
        guard isDetailsValid else {
            errorMessage = "Please fill in all fields correctly"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let url = URL(string: "\(AppConfig.apiBaseURL)/api/v1/registration/request")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: String] = [
                "email": email,
                "fullName": fullName,
                "username": username,
                "phone": phone,
                "idnp": idnp
            ]
            request.httpBody = try JSONEncoder().encode(body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw RegistrationError.badResponse
            }
            
            if httpResponse.statusCode == 201 {
                let result = try JSONDecoder().decode(RequestResponse.self, from: data)
                requestId = result.requestId
                currentStep = .pending
            } else if httpResponse.statusCode == 409 {
                let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                errorMessage = errorResponse?.error ?? "Username is already taken"
            } else {
                let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                errorMessage = errorResponse?.error ?? "Failed to submit registration"
            }
        } catch {
            errorMessage = "Network error: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Resend OTP code
    func resendOTP() async {
        otpCode = ""
        await requestOTP()
        if errorMessage == nil {
            // Stay on OTP step after successful resend
            currentStep = .otp
        }
    }
    
    func goBack() {
        errorMessage = nil
        switch currentStep {
        case .otp:
            currentStep = .email
            otpCode = ""
        case .details:
            currentStep = .otp
        default:
            break
        }
    }
    
    func reset() {
        email = ""
        otpCode = ""
        fullName = ""
        username = ""
        phone = ""
        idnp = ""
        errorMessage = nil
        currentStep = .email
        requestId = nil
    }
}

// MARK: - Response Models

private struct ErrorResponse: Codable {
    let error: String
}

private struct RequestResponse: Codable {
    let requestId: String
}

enum RegistrationError: Error, LocalizedError {
    case badResponse
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .badResponse:
            return "Invalid server response"
        case .serverError(let message):
            return message
        }
    }
}
