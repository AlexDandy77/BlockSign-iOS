import Foundation
import SwiftUI
import CryptoKit
internal import Combine

@MainActor
class DocumentCreationViewModel: ObservableObject {
    @Published var selectedFile: URL?
    @Published var documentTitle: String = ""
    @Published var participants: [String] = [] // List of usernames/emails
    @Published var newParticipant: String = ""
    @Published var isLoading = false
    @Published var error: String?
    @Published var isSuccess = false
    
    func addParticipant() {
        guard !newParticipant.isEmpty else { return }
        if !participants.contains(newParticipant) {
            participants.append(newParticipant)
        }
        newParticipant = ""
    }
    
    func removeParticipant(_ participant: String) {
        participants.removeAll { $0 == participant }
    }
    
    func createDocument() async {
        guard let fileURL = selectedFile else {
            error = "No file selected"
            return
        }
        
        guard !participants.isEmpty else {
            error = "At least one participant is required"
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            // 1. Read file and calculate SHA-256 hash
            let fileData = try Data(contentsOf: fileURL)
            let sha256 = CryptoManager.calculateSHA256(fileData)
            
            // 2. Build canonical payload
            let canonicalPayload = buildCanonicalPayload(
                sha256Hex: sha256,
                title: documentTitle,
                participants: participants
            )
            
            // 3. Sign payload locally
            let signature = try CryptoManager.signChallenge(canonicalPayload)
            
            // 4. Prepare form fields for multipart upload
            // Backend expects participantsUsernames as JSON array string
            let participantsJSON = try JSONSerialization.data(withJSONObject: participants, options: [])
            let participantsString = String(data: participantsJSON, encoding: .utf8) ?? "[]"
            
            let formFields: [String: String] = [
                "sha256Hex": sha256,
                "docTitle": documentTitle,
                "participantsUsernames": participantsString,
                "creatorSignatureB64": signature
            ]
            
            // 5. Upload using multipart/form-data
            let _: DocumentCreateResponse = try await APIClient.shared.uploadMultipart(
                "/api/v1/user/documents",
                fileData: fileData,
                fileName: fileURL.lastPathComponent,
                mimeType: "application/pdf",
                formFields: formFields
            )
            
            isSuccess = true
            
        } catch let apiError as APIError {
            self.error = apiError.errorDescription
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
        
        // Stop accessing security-scoped resource
        selectedFile?.stopAccessingSecurityScopedResource()
    }
    
    private func buildCanonicalPayload(sha256Hex: String, title: String, participants: [String]) -> String {
        // Sort participants alphabetically (case-insensitive to match backend)
        let sorted = participants.sorted { $0.lowercased() < $1.lowercased() }
        
        // Build JSON manually with exact key order expected by backend:
        // sha256Hex -> docTitle -> participantsUsernames
        let participantsJSON = sorted.map { "\"\($0)\"" }.joined(separator: ",")
        
        return "{\"sha256Hex\":\"\(sha256Hex.lowercased())\",\"docTitle\":\"\(title)\",\"participantsUsernames\":[\(participantsJSON)]}"
    }
}
