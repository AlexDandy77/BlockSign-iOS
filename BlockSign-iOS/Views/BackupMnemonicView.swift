import SwiftUI

struct BackupMnemonicView: View {
    let mnemonic: String
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var showCopiedAlert = false
    
    private var words: [String] {
        mnemonic
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
    }
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Warning Card
                        WarningCard()
                        
                        // Mnemonic Grid Card
                        VStack(spacing: 16) {
                            Text("Your Recovery Phrase")
                                .font(.headline)
                                .foregroundColor(AppTheme.textColor(for: colorScheme))
                            
                            if words.count >= 12 {
                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                                        MnemonicWordCell(index: index + 1, word: word)
                                    }
                                }
                            } else {
                                Text(mnemonic)
                                    .font(.body)
                                    .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding()
                        .background(AppTheme.cardBackground(for: colorScheme))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, y: 4)
                        
                        // Copy Button
                        Button(action: copyToClipboard) {
                            HStack {
                                Image(systemName: showCopiedAlert ? "checkmark" : "doc.on.doc")
                                Text(showCopiedAlert ? "Copied!" : "Copy to Clipboard")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: showCopiedAlert 
                                        ? [AppTheme.success, AppTheme.success]
                                        : [AppTheme.primaryBlue, AppTheme.accentBlue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: (showCopiedAlert ? AppTheme.success : AppTheme.primaryBlue).opacity(0.4), radius: 8, y: 4)
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Recovery Phrase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppTheme.primaryBlue)
                }
            }
        }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = mnemonic
        withAnimation {
            showCopiedAlert = true
        }
        
        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedAlert = false
            }
        }
    }
}

// MARK: - Warning Card

struct WarningCard: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(AppTheme.warning)
                Text("Important Security Notice")
                    .font(.headline)
                    .foregroundColor(AppTheme.warning)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                WarningBullet(text: "Write down these words in the exact order shown")
                WarningBullet(text: "Store them in a safe, offline location")
                WarningBullet(text: "Never share your recovery phrase with anyone")
                WarningBullet(text: "Anyone with this phrase can access your account")
                WarningBullet(text: "BlockSign cannot recover this phrase if lost")
            }
        }
        .padding()
        .background(AppTheme.warning.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.warning.opacity(0.3), lineWidth: 1)
        )
    }
}

struct WarningBullet: View {
    @Environment(\.colorScheme) var colorScheme
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
            Text(text)
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
        }
    }
}

// MARK: - Mnemonic Word Cell

struct MnemonicWordCell: View {
    @Environment(\.colorScheme) var colorScheme
    let index: Int
    let word: String
    
    var body: some View {
        HStack(spacing: 8) {
            Text("\(index).")
                .font(.subheadline)
                .foregroundColor(AppTheme.primaryBlue)
                .frame(width: 24, alignment: .trailing)
            
            Text(word)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.textColor(for: colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .background(AppTheme.inputBackground(for: colorScheme))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppTheme.primaryBlue.opacity(0.3), lineWidth: 1)
        )
    }
}
