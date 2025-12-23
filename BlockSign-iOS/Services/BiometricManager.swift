import LocalAuthentication

class BiometricManager {
    static func evaluateFaceID() async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock BlockSign to sign documents"
            )
            return success
        } catch {
            return false
        }
    }
    
    static func isFaceIDAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        let available = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return available && context.biometryType == .faceID
    }
}
