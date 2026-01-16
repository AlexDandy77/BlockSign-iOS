import Foundation
import Security

enum KeychainError: Error {
    case status(OSStatus)
    case itemNotFound
    case unexpectedData
}

class KeychainManager {
    static let serviceName = "md.blocksign.BlockSign"
    
    // MARK: - Private Key Storage
    
    static func storePrivateKey(_ key: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: "ed25519_private_key",
            kSecValueData as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.status(status)
        }
    }
    
    static func retrievePrivateKey() throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: "ed25519_private_key",
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else {
            throw KeychainError.status(status)
        }
        guard let data = result as? Data else {
            throw KeychainError.unexpectedData
        }
        return data
    }
    
    static func hasPrivateKey() -> Bool {
        do {
            _ = try retrievePrivateKey()
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Refresh Token Storage
    
    static func storeRefreshToken(_ token: String) throws {
        let data = token.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: "refresh_token",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.status(status)
        }
    }
    
    static func retrieveRefreshToken() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: "refresh_token",
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else {
            throw KeychainError.status(status)
        }
        guard let data = result as? Data, let token = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        return token
    }
    
    static func hasRefreshToken() -> Bool {
        do {
            _ = try retrieveRefreshToken()
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Access Token Storage
    
    static func storeAccessToken(_ token: String) throws {
        let data = token.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: "access_token",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.status(status)
        }
    }
    
    static func retrieveAccessToken() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: "access_token",
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else {
            throw KeychainError.status(status)
        }
        guard let data = result as? Data, let token = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        return token
    }
    
    // MARK: - Email Storage (for re-authentication)
    
    static func storeEmail(_ email: String) throws {
        let data = email.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: "user_email",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.status(status)
        }
    }
    
    static func retrieveEmail() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: "user_email",
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else {
            throw KeychainError.status(status)
        }
        guard let data = result as? Data, let email = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        return email
    }
    
    // MARK: - Seed Phrase Storage
    
    static func storeSeedPhrase(_ seedPhrase: String) throws {
        let data = seedPhrase.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: "seed_phrase",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.status(status)
        }
    }
    
    static func retrieveSeedPhrase() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: "seed_phrase",
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else {
            throw KeychainError.status(status)
        }
        guard let data = result as? Data, let seedPhrase = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        return seedPhrase
    }
    
    static func hasSeedPhrase() -> Bool {
        do {
            _ = try retrieveSeedPhrase()
            return true
        } catch {
            return false
        }
    }
    
    static func deleteSeedPhrase() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: "seed_phrase"
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    static func deletePrivateKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: "ed25519_private_key"
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Clear All Tokens
    
    static func clearTokens() throws {
        let accounts = ["refresh_token", "access_token", "ed25519_private_key", "user_email", "seed_phrase"]
        for account in accounts {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: account
            ]
            SecItemDelete(query as CFDictionary)
        }
    }
    
    /// Clears only session tokens but keeps the private key and email
    static func clearSessionTokens() throws {
        let accounts = ["refresh_token", "access_token"]
        for account in accounts {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: account
            ]
            SecItemDelete(query as CFDictionary)
        }
    }
}
