import Foundation
internal import Combine

@MainActor
class DocumentManager: ObservableObject {
    @Published var documents: [Document] = []
    @Published var currentUser: UserProfile?
    @Published var isLoading = false
    @Published var error: String?
    
    func fetchMyDocuments() async {
        isLoading = true
        error = nil
        do {
            // The /me endpoint returns user profile with documents
            let response: UserProfileResponse = try await APIClient.shared.request("/api/v1/user/me")
            self.documents = response.documents
            self.currentUser = response.user
            
            // Clean up cached PDFs for documents that no longer exist (rejected/deleted)
            cleanupOrphanedCachedDocuments()
        } catch let apiError as APIError {
            self.error = apiError.errorDescription
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    func refreshDocuments() async {
        await fetchMyDocuments()
    }
    
    func clearState() {
        documents = []
        currentUser = nil
        error = nil
    }
    
    /// Removes cached PDFs for documents that are no longer in the active list
    private func cleanupOrphanedCachedDocuments() {
        let activeDocumentIds = Set(documents.map { $0.id })
        DocumentCache.shared.cleanupOrphanedCache(activeDocumentIds: activeDocumentIds)
    }
}
