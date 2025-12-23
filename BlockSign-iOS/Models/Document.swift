import Foundation

struct Document: Codable, Identifiable {
    let id: String
    let title: String
    let status: DocStatus
    let createdAt: Date
    let updatedAt: Date
    let mimeType: String
    let sizeBytes: Int
    
    // Role and progress information from backend
    let myRole: String?         // "OWNER", "PARTICIPANT", or "VIEWER"
    let progress: DocumentProgress?
    
    let owner: UserInfo
    let participants: [DocumentParticipant]
    let signatures: [Signature]
    
    // sha256Hex is optional in list responses
    let sha256Hex: String?
    
    // Canonical payload for signing (exact JSON string stored by backend)
    let canonicalPayload: String?
    
    // Computed property for display
    var isOwner: Bool {
        return myRole == "OWNER"
    }
    
    var isParticipant: Bool {
        return myRole == "PARTICIPANT"
    }
}

struct DocumentProgress: Codable {
    let totalRequired: Int
    let totalSigned: Int
    
    var progressText: String {
        return "\(totalSigned)/\(totalRequired)"
    }
    
    var isComplete: Bool {
        return totalSigned >= totalRequired
    }
}

enum DocStatus: String, Codable {
    case pending = "PENDING"
    case signed = "SIGNED"
    case rejected = "REJECTED"
}

struct DocumentParticipant: Codable, Identifiable {
    var id: String { user.id }
    let user: UserInfo
    let required: Bool
    let decision: String?
    let decidedAt: Date?
}

struct Signature: Codable, Identifiable {
    var id: String { "\(user.id)-\(signedAt)" }
    let user: UserInfo
    let alg: String // "Ed25519"
    let signedAt: Date
}

struct UserInfo: Codable, Identifiable {
    let id: String
    let email: String?
    let fullName: String?
    let username: String?
    
    var displayName: String {
        if let fullName = fullName, !fullName.isEmpty {
            return fullName
        }
        if let username = username, !username.isEmpty {
            return username
        }
        return email ?? "Unknown"
    }
}

struct BlockchainInfo: Codable {
    let txId: String
    let network: String
    let anchoredAt: Date?
    let explorerUrl: String?
    let blockNumber: Int?
    let confirmed: Bool?
}
