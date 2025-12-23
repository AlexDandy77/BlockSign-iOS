import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let fullName: String?
    let username: String?
    let role: String  // Using String for flexibility - backend returns "USER" or "ADMIN"
    
    // Optional fields that may not be in all responses
    let status: String?
    let createdAt: Date?
    let updatedAt: Date?
    
    // Computed property for display name
    var displayName: String {
        if let fullName = fullName, !fullName.isEmpty {
            return fullName
        }
        if let username = username, !username.isEmpty {
            return username
        }
        return email
    }
    
    // Convenience initializer for creating User from different response types
    init(id: String, email: String, fullName: String?, username: String? = nil, role: String, status: String? = nil, createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.username = username
        self.role = role
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum UserRole: String, Codable {
    case user = "USER"
    case admin = "ADMIN"
}

enum UserStatus: String, Codable {
    case active = "ACTIVE"
    case suspended = "SUSPENDED"
}
