import Foundation
internal import Combine

struct VerificationResult {
    let matched: Bool
    let sha256: String
    let document: VerifiedDocument?
    let blockchain: BlockchainInfo?
}

@MainActor
class DocumentVerificationViewModel: ObservableObject {
    @Published var selectedFile: URL?
    @Published var verificationResult: VerificationResult?
    @Published var isLoading = false
    @Published var error: String?
    
    func verifyDocument() async {
        guard let fileURL = selectedFile else { return }
        
        isLoading = true
        error = nil
        
        do {
            let fileData = try Data(contentsOf: fileURL)
            
            // Use multipart upload (server expects file in multipart/form-data)
            let response: VerificationResponse = try await APIClient.shared.uploadMultipartPublic(
                "/api/v1/documents/verify",
                fileData: fileData,
                fileName: fileURL.lastPathComponent,
                mimeType: "application/pdf"
            )
            
            self.verificationResult = VerificationResult(
                matched: response.match,
                sha256: response.sha256Hex,
                document: response.document,
                blockchain: response.document?.blockchain
            )
            
        } catch let apiError as APIError {
            self.error = apiError.errorDescription
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
        
        // Stop accessing security-scoped resource
        selectedFile?.stopAccessingSecurityScopedResource()
    }
    
    func reset() {
        selectedFile = nil
        verificationResult = nil
        error = nil
    }
}
