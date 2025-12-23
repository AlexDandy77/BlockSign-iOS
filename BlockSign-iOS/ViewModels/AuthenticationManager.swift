import Foundation
import SwiftUI
internal import Combine

/// Authentication states for the login flow
enum AuthenticationState: Equatable {
    case unknown           // Initial state, checking credentials
    case unauthenticated   // No valid session, show login
    case awaitingChallenge // User entered email, requesting challenge
    case awaitingSeedPhrase(email: String, challenge: String) // Challenge received, awaiting seed phrase
    case authenticating    // Signing and completing auth
    case authenticated     // Successfully logged in
    case requiresFaceID    // Has stored credentials, needs FaceID unlock
}

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var state: AuthenticationState = .unknown
    @Published var user: User?
    @Published var isLoading = false
    @Published var error: String?
    
    // Convenience computed property for backward compatibility
    var isAuthenticated: Bool {
        state == .authenticated
    }
    
    init() {
        // Set self as APIClient delegate for re-authentication callbacks
        APIClient.shared.delegate = self
        Task { await checkStoredCredentials() }
    }
    
    // MARK: - Credential Check on App Launch
    
    /// Checks if we have stored credentials and can attempt automatic login
    private func checkStoredCredentials() async {
        // Check if we have stored tokens
        guard KeychainManager.hasRefreshToken() else {
            state = .unauthenticated
            return
        }
        
        // We have a refresh token - require FaceID to unlock
        state = .requiresFaceID
    }
    
    // MARK: - FaceID Authentication Flow
    
    /// Attempts to authenticate using FaceID and stored credentials
    func authenticateWithFaceID() async {
        isLoading = true
        error = nil
        
        // Verify FaceID
        let faceIDSuccess = await BiometricManager.evaluateFaceID()
        guard faceIDSuccess else {
            error = "FaceID authentication failed"
            isLoading = false
            return
        }
        
        // Try to restore session with stored tokens
        do {
            // Restore access token from keychain
            if let accessToken = try? KeychainManager.retrieveAccessToken() {
                APIClient.shared.setAccessToken(accessToken)
            }
            
            // Try to access /me endpoint - this will automatically refresh if needed
            let response: UserProfileResponse = try await APIClient.shared.request("/api/v1/user/me")
            
            // Convert UserProfile to User for backward compatibility
            self.user = User(
                id: response.user.id,
                email: response.user.email,
                fullName: response.user.fullName,
                role: response.user.role
            )
            
            // Store the current access token
            if let token = APIClient.shared.getAccessToken() {
                try? KeychainManager.storeAccessToken(token)
            }
            
            state = .authenticated
            
        } catch {
            // Token refresh failed or request failed - need to re-login
            self.error = "Session expired. Please log in again."
            await forceLogout()
        }
        
        isLoading = false
    }
    
    // MARK: - Login Flow Step 1: Request Challenge
    
    /// Step 1: User enters email, request challenge from server
    func requestChallenge(email: String) async {
        isLoading = true
        error = nil
        state = .awaitingChallenge
        
        do {
            let request = AuthChallengeRequest(email: email)
            let response: AuthChallengeResponse = try await APIClient.shared.unauthenticatedRequest(
                "/api/v1/auth/challenge",
                method: "POST",
                body: request
            )
            
            // Store email for later
            try? KeychainManager.storeEmail(email)
            
            // Move to next step - awaiting seed phrase
            state = .awaitingSeedPhrase(email: email, challenge: response.challenge)
            
        } catch let apiError as APIError {
            self.error = apiError.errorDescription
            state = .unauthenticated
        } catch {
            self.error = "User not found. Please check your email."
            state = .unauthenticated
        }
        
        isLoading = false
    }
    
    // MARK: - Login Flow Step 2: Complete Authentication
    
    /// Step 2: User enters seed phrase, derive key, sign challenge, complete auth
    func completeAuthentication(seedPhrase: String) async {
        guard case .awaitingSeedPhrase(let email, let challenge) = state else {
            error = "Invalid state for authentication"
            return
        }
        
        isLoading = true
        error = nil
        state = .authenticating
        
        do {
            // 1. Derive private key from seed phrase using HD derivation (matching backend)
            let _ = try CryptoManager.restoreKeyPair(from: seedPhrase)
            
            // 1.5. Store seed phrase for recovery display
            try KeychainManager.storeSeedPhrase(seedPhrase)
            
            // 2. Sign the challenge
            let signature = try CryptoManager.signChallenge(challenge)
            
            // 3. Complete authentication
            let completeRequest = AuthCompleteRequest(
                email: email,
                challenge: challenge,
                signatureB64: signature
            )
            
            let response: AuthCompleteResponse = try await APIClient.shared.unauthenticatedRequest(
                "/api/v1/auth/complete",
                method: "POST",
                body: completeRequest
            )
            
            // 4. Store tokens
            APIClient.shared.setAccessToken(response.accessToken)
            try KeychainManager.storeAccessToken(response.accessToken)
            try KeychainManager.storeRefreshToken(response.refreshToken)
            
            // 5. Set user
            self.user = response.user
            state = .authenticated
            
        } catch let apiError as APIError {
            self.error = apiError.errorDescription
            // Go back to seed phrase entry
            if case .awaitingSeedPhrase = state {
                // Keep current state
            } else {
                state = .unauthenticated
            }
        } catch {
            self.error = "Authentication failed: \(error.localizedDescription)"
            state = .unauthenticated
        }
        
        isLoading = false
    }
    
    // MARK: - Back to Email Entry
    
    /// Go back to email entry from seed phrase step
    func backToEmailEntry() {
        state = .unauthenticated
        error = nil
    }
    
    // MARK: - Logout
    
    /// Logs out the user and clears all stored credentials
    func logout() async {
        do {
            // Call backend logout
            let _: EmptyResponse = try await APIClient.shared.request("/api/v1/auth/logout", method: "POST")
        } catch {
            print("Logout API error: \(error)")
        }
        
        await forceLogout()
    }
    
    /// Forces logout without calling the server (used when tokens are invalid)
    func forceLogout() async {
        do {
            try KeychainManager.clearTokens()
        } catch {
            print("Keychain clear error: \(error)")
        }
        
        APIClient.shared.clearAccessToken()
        user = nil
        state = .unauthenticated
    }
}

// MARK: - APIClientDelegate

extension AuthenticationManager: APIClientDelegate {
    func apiClientDidRequireReauthentication() {
        Task { @MainActor in
            self.error = "Session expired. Please log in again."
            await self.forceLogout()
        }
    }
}
