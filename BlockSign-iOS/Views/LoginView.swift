import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.colorScheme) var colorScheme
    @State private var email: String = ""
    @State private var seedPhraseWords: [String] = Array(repeating: "", count: 12)
    @State private var showRegistration: Bool = false
    @FocusState private var focusedField: Int?
    
    // Theme-aware colors
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
    
    // Check if we're in seed phrase entry mode
    private var isInSeedPhraseMode: Bool {
        if case .awaitingSeedPhrase = authManager.state {
            return true
        }
        return false
    }
    
    var body: some View {
        NavigationView {
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
                
                VStack(spacing: isInSeedPhraseMode ? 12 : 24) {
                    // Header - compact in seed phrase mode
                    if !isInSeedPhraseMode {
                        headerView
                        Spacer()
                    }
                    
                    // Content based on state
                    switch authManager.state {
                    case .unauthenticated, .awaitingChallenge:
                        emailEntryView
                        
                    case .awaitingSeedPhrase(let email, _):
                        seedPhraseEntryView(email: email)
                        
                    case .authenticating:
                        authenticatingView
                        
                    case .requiresFaceID:
                        faceIDView
                        
                    case .unknown:
                        ProgressView("Checking credentials...")
                            .foregroundColor(textColor)
                        
                    case .authenticated:
                        ProgressView("Loading...")
                            .foregroundColor(textColor)
                    }
                    
                    // Error display
                    if let error = authManager.error {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    if !isInSeedPhraseMode {
                        Spacer()
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 12) {
            // Logo with glow effect
            ZStack {
                Image(systemName: "signature")
                    .font(.system(size: 70))
                    .foregroundColor(AppTheme.primaryBlue)
                    .blur(radius: 20)
                    .opacity(0.5)
                
                Image(systemName: "signature")
                    .font(.system(size: 60))
                    .foregroundColor(AppTheme.primaryBlue)
            }
            
            Text("BlockSign")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(textColor)
            
            Text("Secure Document Signing")
                .font(.subheadline)
                .foregroundColor(secondaryTextColor)
        }
        .padding(.top, 40)
    }
    
    // MARK: - Email Entry View (Step 1)
    
    private var emailEntryView: some View {
        VStack(spacing: 20) {
            Text("Enter your email to login")
                .font(.headline)
                .foregroundColor(textColor)
            
            // Styled text field
            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundColor(AppTheme.primaryBlue)
                
                TextField("Email", text: $email)
                    .foregroundColor(textColor)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
            }
            .padding()
            .background(inputBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.primaryBlue.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal)
            
            if authManager.isLoading {
                ProgressView()
                    .tint(AppTheme.primaryBlue)
                    .padding()
            } else {
                Button(action: {
                    Task {
                        await authManager.requestChallenge(email: email)
                    }
                }) {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: email.isEmpty 
                                    ? [Color.gray, Color.gray]
                                    : [AppTheme.primaryBlue, AppTheme.accentBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: email.isEmpty ? .clear : AppTheme.primaryBlue.opacity(0.4), radius: 8, y: 4)
                }
                .padding(.horizontal)
                .disabled(email.isEmpty)
            }
            
            // Create Account link
            Button(action: { showRegistration = true }) {
                Text("Don't have an account? ")
                    .foregroundColor(secondaryTextColor) +
                Text("Create one")
                    .foregroundColor(AppTheme.primaryBlue)
                    .fontWeight(.semibold)
            }
            .padding(.top, 8)
        }
        .sheet(isPresented: $showRegistration) {
            RegistrationEmailView(viewModel: RegistrationViewModel())
        }
    }
    
    // MARK: - Seed Phrase Entry View (Step 2)
    
    private func seedPhraseEntryView(email: String) -> some View {
        VStack(spacing: 12) {
            // Back button and email header
            HStack {
                Button(action: {
                    authManager.backToEmailEntry()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(AppTheme.primaryBlue)
                }
                
                Spacer()
            }
            
            Text("Logging in as")
                .font(.subheadline)
                .foregroundColor(secondaryTextColor)
            
            Text(email)
                .font(.headline)
                .foregroundColor(textColor)
            
            Rectangle()
                .fill(AppTheme.primaryBlue.opacity(0.3))
                .frame(height: 1)
                .padding(.vertical, 4)
            
            Text("Mnemonic phrase")
                .font(.headline)
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Grid of seed phrase inputs
            ThemedMnemonicInputGrid(
                words: $seedPhraseWords,
                focusedField: $focusedField,
                cardBackground: cardBackground,
                inputBackground: inputBackground,
                textColor: textColor
            )
            
            // Actions row
            HStack {
                Button("Paste") {
                    pasteFromClipboard()
                }
                .foregroundColor(AppTheme.primaryBlue)
                
                Spacer()
                
                Button("Clear all") {
                    seedPhraseWords = Array(repeating: "", count: 12)
                    focusedField = 0
                }
                .foregroundColor(AppTheme.primaryBlue)
            }
            
            Spacer()
            
            if authManager.isLoading {
                ProgressView()
                    .tint(AppTheme.primaryBlue)
                    .padding()
            } else {
                Button(action: {
                    let seedPhrase = seedPhraseWords.joined(separator: " ")
                    Task {
                        await authManager.completeAuthentication(seedPhrase: seedPhrase)
                    }
                }) {
                    Text("Submit")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: isValidSeedPhrase 
                                    ? [AppTheme.primaryBlue, AppTheme.accentBlue]
                                    : [Color.gray, Color.gray],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: isValidSeedPhrase ? AppTheme.primaryBlue.opacity(0.4) : .clear, radius: 8, y: 4)
                }
                .disabled(!isValidSeedPhrase)
            }
        }
    }
    
    // MARK: - Paste from Clipboard
    
    private func pasteFromClipboard() {
        guard let clipboardText = UIPasteboard.general.string else { return }
        
        let words = clipboardText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        
        for (index, word) in words.prefix(12).enumerated() {
            seedPhraseWords[index] = word.lowercased()
        }
    }
    
    // MARK: - Authenticating View
    
    private var authenticatingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(AppTheme.primaryBlue)
                .scaleEffect(1.2)
            Text("Signing in...")
                .foregroundColor(secondaryTextColor)
        }
    }
    
    // MARK: - FaceID View
    
    private var faceIDView: some View {
        VStack(spacing: 24) {
            ZStack {
                Image(systemName: "faceid")
                    .font(.system(size: 70))
                    .foregroundColor(AppTheme.primaryBlue)
                    .blur(radius: 20)
                    .opacity(0.5)
                
                Image(systemName: "faceid")
                    .font(.system(size: 60))
                    .foregroundColor(AppTheme.primaryBlue)
            }
            
            Text("Unlock with Face ID")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(textColor)
            
            Text("Use Face ID to access your account")
                .font(.subheadline)
                .foregroundColor(secondaryTextColor)
            
            if authManager.isLoading {
                ProgressView()
                    .tint(AppTheme.primaryBlue)
                    .padding()
            } else {
                Button(action: {
                    Task {
                        await authManager.authenticateWithFaceID()
                    }
                }) {
                    Text("Unlock")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: AppTheme.primaryBlue.opacity(0.4), radius: 8, y: 4)
                }
                .padding(.horizontal)
                
                Button(action: {
                    Task {
                        await authManager.forceLogout()
                    }
                }) {
                    Text("Use Different Account")
                        .foregroundColor(AppTheme.primaryBlue)
                }
            }
        }
        .onAppear {
            Task {
                await authManager.authenticateWithFaceID()
            }
        }
    }
    
    // MARK: - Helpers
    
    private var isValidSeedPhrase: Bool {
        let filledWords = seedPhraseWords.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        return filledWords.count == 12 || filledWords.count == 24
    }
}

// MARK: - Themed Mnemonic Input Grid

struct ThemedMnemonicInputGrid: View {
    @Binding var words: [String]
    var focusedField: FocusState<Int?>.Binding
    let cardBackground: Color
    let inputBackground: Color
    let textColor: Color
    
    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(0..<12, id: \.self) { index in
                ThemedMnemonicInputCell(
                    index: index + 1,
                    word: $words[index],
                    focusedField: focusedField,
                    fieldIndex: index,
                    inputBackground: inputBackground,
                    textColor: textColor,
                    onNext: {
                        if index < 11 {
                            focusedField.wrappedValue = index + 1
                        } else {
                            focusedField.wrappedValue = nil
                        }
                    }
                )
            }
        }
        .padding(12)
        .background(cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Themed Mnemonic Input Cell

struct ThemedMnemonicInputCell: View {
    let index: Int
    @Binding var word: String
    var focusedField: FocusState<Int?>.Binding
    let fieldIndex: Int
    let inputBackground: Color
    let textColor: Color
    let onNext: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text("\(index).")
                .font(.subheadline)
                .foregroundColor(AppTheme.primaryBlue)
                .frame(width: 22, alignment: .trailing)
            
            TextField("", text: $word)
                .font(.body)
                .foregroundColor(textColor)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .textContentType(.none)
                .focused(focusedField, equals: fieldIndex)
                .submitLabel(index < 12 ? .next : .done)
                .onSubmit(onNext)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .background(inputBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppTheme.primaryBlue.opacity(0.3), lineWidth: 1)
        )
    }
}
