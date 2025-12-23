import Foundation

// MARK: - Auth Models

struct AuthChallengeRequest: Codable {
    let email: String
}

struct AuthChallengeResponse: Codable {
    let challenge: String
}

struct AuthCompleteRequest: Codable {
    let email: String
    let challenge: String
    let signatureB64: String
}

struct AuthCompleteResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: User
}

struct RefreshResponse: Codable {
    let accessToken: String
    let refreshToken: String
}

struct EmptyResponse: Codable {}

// MARK: - User Profile Response (matches /me endpoint)

struct UserProfileResponse: Codable {
    let user: UserProfile
    let documents: [Document]
}

struct UserProfile: Codable {
    let id: String
    let email: String
    let fullName: String?
    let username: String?
    let role: String
    let status: String
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Documents
struct DocumentListResponse: Codable {
    let user: User
    let documents: [Document]
}

struct DocumentCreateRequest: Codable {
    let sha256Hex: String
    let docTitle: String
    let participantsUsernames: [String]
    let creatorSignatureB64: String
    let file: Data // This might need to be handled as multipart/form-data in reality, but spec implies JSON body with file? 
                   // Spec says: "Input: { ..., file: PDF }". Usually this means multipart. 
                   // But the ViewModel example shows `body: DocumentCreateRequest(...)`. 
                   // If `file` is Data, it will be base64 encoded in JSON.
}

struct DocumentCreateResponse: Codable {
    let documentId: String
    let status: String
    let createdAt: Date
}

struct SigningRequest: Codable {
    let signatureB64: String
}

struct SigningResponse: Codable {
    let status: DocStatus
    let blockchain: BlockchainInfo?
}

// MARK: - Verification Models

struct VerificationResponse: Codable {
    let match: Bool
    let sha256Hex: String
    let document: VerifiedDocument?
}

/// Document structure returned by the verification endpoint (includes blockchain info)
struct VerifiedDocument: Codable {
    let id: String
    let title: String
    let createdAt: Date
    let status: DocStatus
    let owner: UserInfo
    let participants: [DocumentParticipant]
    let signatures: [Signature]
    let blockchain: BlockchainInfo?
}
