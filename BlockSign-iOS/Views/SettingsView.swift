import SwiftUI

struct SettingsView: View {
    @StateObject var viewModel = SettingsViewModel()
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.colorScheme) var colorScheme
    @State var showBackupMnemonic = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Security Section
                        SettingsSectionCard(title: "Security") {
                            if BiometricManager.isFaceIDAvailable() {
                                HStack {
                                    Image(systemName: "faceid")
                                        .font(.title2)
                                        .foregroundColor(AppTheme.primaryBlue)
                                    Text("Face ID Enabled")
                                        .foregroundColor(AppTheme.textColor(for: colorScheme))
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AppTheme.success)
                                }
                                
                                Divider()
                                    .background(AppTheme.primaryBlue.opacity(0.2))
                            }
                            
                            Button(action: {
                                Task {
                                    await viewModel.authenticateAndShowMnemonic()
                                    if viewModel.isAuthenticated {
                                        showBackupMnemonic = true
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: "key.fill")
                                        .font(.title2)
                                        .foregroundColor(AppTheme.primaryBlue)
                                    Text("View Recovery Phrase")
                                        .foregroundColor(AppTheme.textColor(for: colorScheme))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(AppTheme.primaryBlue.opacity(0.6))
                                }
                            }
                            
                            if let error = viewModel.authError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(AppTheme.error)
                            }
                        }
                        
                        // Account Section
                        SettingsSectionCard(title: "Account") {
                            if let user = authManager.user {
                                SettingsRow(icon: "envelope.fill", label: "Email", value: user.email)
                                
                                if let username = user.username, !username.isEmpty {
                                    Divider()
                                        .background(AppTheme.primaryBlue.opacity(0.2))
                                    SettingsRow(icon: "person.fill", label: "Username", value: username)
                                }
                                
                                if let fullName = user.fullName, !fullName.isEmpty {
                                    Divider()
                                        .background(AppTheme.primaryBlue.opacity(0.2))
                                    SettingsRow(icon: "person.text.rectangle.fill", label: "Full Name", value: fullName)
                                }
                                
                                Divider()
                                    .background(AppTheme.primaryBlue.opacity(0.2))
                            }
                            
                            Button(action: {
                                Task {
                                    await authManager.logout()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.title2)
                                        .foregroundColor(AppTheme.error)
                                    Text("Logout")
                                        .foregroundColor(AppTheme.error)
                                    Spacer()
                                }
                            }
                        }
                        
                        // About Section
                        SettingsSectionCard(title: "About") {
                            SettingsRow(icon: "info.circle.fill", label: "Version", value: "1.0.0")
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showBackupMnemonic, onDismiss: {
            viewModel.resetAuthentication()
        }) {
            BackupMnemonicView(mnemonic: viewModel.mnemonicBackup)
        }
    }
}

// MARK: - Settings Section Card

struct SettingsSectionCard<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                .padding(.leading, 4)
            
            VStack(spacing: 16) {
                content
            }
            .padding()
            .background(AppTheme.cardBackground(for: colorScheme))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, y: 4)
        }
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AppTheme.primaryBlue)
            Text(label)
                .foregroundColor(AppTheme.textColor(for: colorScheme))
            Spacer()
            Text(value)
                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
        }
    }
}
