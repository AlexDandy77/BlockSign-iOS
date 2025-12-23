import Foundation
import CryptoKit
internal import Combine

@MainActor
class DocumentSigningViewModel: ObservableObject {
    @Published var document: Document
    @Published var isLoading = false
    @Published var error: String?
    @Published var signedSuccessfully = false
    @Published var rejectedSuccessfully = false
    @Published var documentData: Data?  // Cached PDF data
    @Published var isLoadingDocument = false
    @Published var isDocumentExpired = false  // True if document file is no longer available
    
    init(document: Document) {
        self.document = document
        // Don't load cache in init - it will be loaded when needed in fetchDocumentFile()
    }
    
    // MARK: - Fetch Document PDF
    
    /// Fetches the document PDF file for viewing and caches it for signing
    func fetchDocumentFile() async {
        isLoadingDocument = true
        error = nil
        isDocumentExpired = false
        
        // First check if we already have it in memory
        if documentData != nil {
            isLoadingDocument = false
            return
        }
        
        // Try local cache first
        if let cached = DocumentCache.shared.retrieve(for: document.id) {
            self.documentData = cached
            isLoadingDocument = false
            return
        }
        
        // Fetch from server
        do {
            let data = try await APIClient.shared.downloadFile("/api/v1/user/documents/\(document.id)/view")
            self.documentData = data
            // Cache locally for future use
            DocumentCache.shared.save(data: data, for: document.id)
        } catch let apiError as APIError {
            // Check if it's a "key doesn't exist" error (S3 expired)
            if case .httpError(let code, let message) = apiError {
                if code == 500 && message.lowercased().contains("key") && message.lowercased().contains("exist") {
                    self.isDocumentExpired = true
                    self.error = "Document file has expired and is no longer available for viewing."
                } else {
                    self.error = apiError.errorDescription
                }
            } else {
                self.error = apiError.errorDescription
            }
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoadingDocument = false
    }
    
    // MARK: - Sign Document
    
    func signDocument() async {
        isLoading = true
        error = nil
        
        do {
            // 1. Prompt FaceID for confirmation
            let faceIDPassed = await BiometricManager.evaluateFaceID()
            guard faceIDPassed else {
                throw NSError(domain: "App", code: -1, userInfo: [NSLocalizedDescriptionKey: "Biometric authentication required to sign"])
            }
            
            // 2. Get or fetch document data to calculate SHA256
            var fileData = documentData
            if fileData == nil {
                // Try local cache
                if let cached = DocumentCache.shared.retrieve(for: document.id) {
                    fileData = cached
                    documentData = cached
                } else {
                    // Fetch from server
                    do {
                        fileData = try await APIClient.shared.downloadFile("/api/v1/user/documents/\(document.id)/view")
                        documentData = fileData
                        // Cache it
                        if let data = fileData {
                            DocumentCache.shared.save(data: data, for: document.id)
                        }
                    } catch let apiError as APIError {
                        if case .httpError(let code, let message) = apiError {
                            if code == 500 && message.lowercased().contains("key") && message.lowercased().contains("exist") {
                                throw NSError(domain: "App", code: -1, userInfo: [NSLocalizedDescriptionKey: "Document file has expired. Cannot sign without the original file."])
                            }
                        }
                        throw apiError
                    }
                }
            }
            
            guard let pdfData = fileData else {
                throw NSError(domain: "App", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not fetch document file"])
            }
            
            // 3. Calculate SHA256 from the PDF file
            let sha256Hex = CryptoManager.calculateSHA256(pdfData)
            
            // 4. Build canonical payload (same format as document creation)
            let canonicalPayload = buildCanonicalPayload(sha256Hex: sha256Hex)
            
            // 5. Sign the payload using stored private key
            let signature = try CryptoManager.signChallenge(canonicalPayload)
            
            // 6. Send signature to backend
            let _: SigningResponse = try await APIClient.shared.request(
                "/api/v1/user/documents/\(document.id)/sign",
                method: "POST",
                body: SigningRequest(signatureB64: signature)
            )
            
            signedSuccessfully = true
            
        } catch let apiError as APIError {
            self.error = apiError.errorDescription
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func rejectDocument(reason: String) async {
        isLoading = true
        error = nil
        
        do {
            struct RejectRequest: Codable {
                let reason: String
            }
            
            let _: EmptyResponse = try await APIClient.shared.request(
                "/api/v1/user/documents/\(document.id)/reject",
                method: "POST",
                body: RejectRequest(reason: reason)
            )
            
            // Clear cached PDF since document is rejected
            DocumentCache.shared.remove(documentId: document.id)
            documentData = nil
            
            rejectedSuccessfully = true
            
        } catch let apiError as APIError {
            self.error = apiError.errorDescription
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Build Canonical Payload
    
    /// Builds the canonical payload for signing (must match backend exactly)
    private func buildCanonicalPayload(sha256Hex: String) -> String {
        // Get participant usernames and sort them (case-insensitive, matching backend's localeCompare)
        let participantUsernames = document.participants
            .compactMap { $0.user.username }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        
        // Build JSON manually with exact key order expected by backend:
        // sha256Hex -> docTitle -> participantsUsernames
        let participantsJSON = participantUsernames.map { "\"\($0)\"" }.joined(separator: ",")
        
        return "{\"sha256Hex\":\"\(sha256Hex.lowercased())\",\"docTitle\":\"\(document.title)\",\"participantsUsernames\":[\(participantsJSON)]}"
    }
}
