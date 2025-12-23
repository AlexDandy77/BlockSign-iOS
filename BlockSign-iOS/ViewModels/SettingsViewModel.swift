import Foundation
internal import Combine
import LocalAuthentication

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var mnemonicBackup: String = ""
    @Published var isAuthenticated: Bool = false
    @Published var authError: String?
    
    init() {
        // Initialization
    }
    
    func authenticateAndShowMnemonic() async {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            authError = "Biometric authentication not available"
            return
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Authenticate to view your recovery phrase"
            )
            
            if success {
                retrieveSeedPhrase()
                isAuthenticated = true
            }
        } catch {
            authError = "Authentication failed: \(error.localizedDescription)"
        }
    }
    
    private func retrieveSeedPhrase() {
        do {
            mnemonicBackup = try KeychainManager.retrieveSeedPhrase()
        } catch {
            mnemonicBackup = "Unable to retrieve recovery phrase. Please ensure you have it stored securely."
        }
    }
    
    func resetAuthentication() {
        isAuthenticated = false
        mnemonicBackup = ""
        authError = nil
    }
}
