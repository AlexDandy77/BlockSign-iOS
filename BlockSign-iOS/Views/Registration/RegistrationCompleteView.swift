import SwiftUI
internal import Combine

/// Final step: Complete registration via deep link with mnemonic generation
struct RegistrationCompleteView: View {
    let token: String
    let onComplete: () -> Void
    let onDismiss: () -> Void
    
    @StateObject private var viewModel = RegistrationCompleteViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var hasConfirmed = false
    
    private var backgroundColor: Color {
        AppTheme.backgroundColor(for: colorScheme)
    }
    
    private var cardBackground: Color {
        AppTheme.cardBackground(for: colorScheme)
    }
    
    private var inputBackground: Color {
        AppTheme.inputBackground(for: colorScheme)
    }
    
    private var textColor: Color {
        AppTheme.textColor(for: colorScheme)
    }
    
    private var secondaryTextColor: Color {
        AppTheme.secondaryTextColor(for: colorScheme)
    }
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    backgroundColor,
                    colorScheme == .dark
                        ? Color(red: 0.08, green: 0.12, blue: 0.25)
                        : Color(red: 0.90, green: 0.94, blue: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Image(systemName: "key.fill")
                                .font(.system(size: 50))
                                .foregroundColor(AppTheme.primaryBlue)
                                .blur(radius: 15)
                                .opacity(0.5)
                            
                            Image(systemName: "key.fill")
                                .font(.system(size: 40))
                                .foregroundColor(AppTheme.primaryBlue)
                        }
                        
                        Text("Secure Your Account")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(textColor)
                        
                        Text("Save your recovery phrase to complete registration")
                            .font(.subheadline)
                            .foregroundColor(secondaryTextColor)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Warning card
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Important!")
                                .font(.headline)
                                .foregroundColor(textColor)
                            Text("Write down these 12 words and store them safely. This is the only way to recover your account.")
                                .font(.caption)
                                .foregroundColor(secondaryTextColor)
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    
                    // Mnemonic display
                    if viewModel.isGenerating {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Generating secure phrase...")
                                .foregroundColor(secondaryTextColor)
                        }
                        .frame(height: 300)
                    } else if let words = viewModel.mnemonicWords {
                        VStack(spacing: 16) {
                            // 6x2 grid of words (2 columns)
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 10) {
                                ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                                    HStack(spacing: 8) {
                                        Text("\(index + 1).")
                                            .font(.subheadline)
                                            .foregroundColor(secondaryTextColor)
                                            .frame(width: 24, alignment: .trailing)
                                        
                                        Text(word)
                                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                                            .foregroundColor(textColor)
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 14)
                                    .frame(maxWidth: .infinity)
                                    .background(inputBackground)
                                    .cornerRadius(10)
                                }
                            }
                            
                            // Copy button
                            Button(action: {
                                UIPasteboard.general.string = words.joined(separator: " ")
                                // Show feedback
                            }) {
                                HStack {
                                    Image(systemName: "doc.on.doc")
                                    Text("Copy to Clipboard")
                                }
                                .font(.subheadline)
                                .foregroundColor(AppTheme.primaryBlue)
                            }
                        }
                        .padding(20)
                        .background(cardBackground)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
                        .padding(.horizontal)
                    }
                    
                    // Confirmation checkbox
                    Button(action: { hasConfirmed.toggle() }) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: hasConfirmed ? "checkmark.square.fill" : "square")
                                .foregroundColor(hasConfirmed ? AppTheme.primaryBlue : secondaryTextColor)
                                .font(.title3)
                            
                            Text("I have written down my recovery phrase and stored it safely. I understand that losing this phrase means losing access to my account.")
                                .font(.caption)
                                .foregroundColor(secondaryTextColor)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Error message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Complete button
                    Button(action: {
                        Task {
                            let success = await viewModel.completeRegistration(token: token)
                            if success {
                                onComplete()
                            }
                        }
                    }) {
                        HStack {
                            if viewModel.isCompleting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Complete Registration")
                                Image(systemName: "checkmark.seal.fill")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(hasConfirmed && viewModel.mnemonicWords != nil ? AppTheme.primaryBlue : Color.gray.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!hasConfirmed || viewModel.mnemonicWords == nil || viewModel.isCompleting)
                    .padding(.horizontal, 24)
                    
                    // Cancel button
                    Button(action: onDismiss) {
                        Text("Cancel")
                            .foregroundColor(secondaryTextColor)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            viewModel.generateMnemonic()
        }
    }
}

// MARK: - ViewModel

@MainActor
class RegistrationCompleteViewModel: ObservableObject {
    @Published var mnemonicWords: [String]?
    @Published var isGenerating = false
    @Published var isCompleting = false
    @Published var errorMessage: String?
    
    private var mnemonic: String?
    
    func generateMnemonic() {
        isGenerating = true
        errorMessage = nil
        
        // Generate BIP39 mnemonic (12 words, 128-bit entropy)
        if let generatedMnemonic = BIP39.generateMnemonic(strength: 128) {
            mnemonic = generatedMnemonic
            mnemonicWords = generatedMnemonic.components(separatedBy: " ")
        } else {
            errorMessage = "Failed to generate secure phrase"
        }
        
        isGenerating = false
    }
    
    func completeRegistration(token: String) async -> Bool {
        guard let mnemonic = mnemonic else {
            errorMessage = "No recovery phrase generated"
            return false
        }
        
        isCompleting = true
        errorMessage = nil
        
        do {
            // 1. Derive keypair from mnemonic
            let (publicKeyHex, privateKeyData) = try CryptoManager.restoreKeyPair(from: mnemonic)
            
            // 2. Sign the token as proof of key ownership
            let tokenData = token.data(using: .utf8)!
            let signature = try Ed25519Pure.sign(message: tokenData, privateKey: privateKeyData)
            let signatureB64 = signature.base64EncodedString()
            
            // 3. Store the seed phrase in keychain
            try KeychainManager.storeSeedPhrase(mnemonic)
            
            // 4. Call /complete endpoint
            let url = URL(string: "\(AppConfig.apiBaseURL)/api/v1/registration/complete")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: String] = [
                "token": token,
                "publicKeyEd25519Hex": publicKeyHex,
                "signatureB64": signatureB64
            ]
            request.httpBody = try JSONEncoder().encode(body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw RegistrationError.badResponse
            }
            
            if httpResponse.statusCode == 201 {
                // Success! User is now registered
                isCompleting = false
                return true
            } else {
                let errorResponse = try? JSONDecoder().decode(ErrorResponseComplete.self, from: data)
                errorMessage = errorResponse?.error ?? "Failed to complete registration"
            }
        } catch {
            errorMessage = error.localizedDescription
            // Clean up on failure
            try? KeychainManager.deleteSeedPhrase()
            try? KeychainManager.deletePrivateKey()
        }
        
        isCompleting = false
        return false
    }
}

private struct ErrorResponseComplete: Codable {
    let error: String
}
