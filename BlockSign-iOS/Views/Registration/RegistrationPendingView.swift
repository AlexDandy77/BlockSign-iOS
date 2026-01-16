import SwiftUI

/// Step 4: Pending approval screen after registration request submission
struct RegistrationPendingView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    var onDismissAll: (() -> Void)? = nil
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    private var backgroundColor: Color {
        AppTheme.backgroundColor(for: colorScheme)
    }
    
    private var cardBackground: Color {
        AppTheme.cardBackground(for: colorScheme)
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
            
            VStack(spacing: 24) {
                Spacer()
                
                // Success animation
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 90, height: 90)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                }
                
                // Title
                Text("Request Submitted!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
                
                // Message card
                VStack(spacing: 20) {
                    Text("Your registration request has been submitted successfully.")
                        .font(.body)
                        .foregroundColor(textColor)
                        .multilineTextAlignment(.center)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "1.circle.fill")
                                .foregroundColor(AppTheme.primaryBlue)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Admin Review")
                                    .font(.headline)
                                    .foregroundColor(textColor)
                                Text("An administrator will review your request.")
                                    .font(.subheadline)
                                    .foregroundColor(secondaryTextColor)
                            }
                        }
                        
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "2.circle.fill")
                                .foregroundColor(AppTheme.primaryBlue)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Email Notification")
                                    .font(.headline)
                                    .foregroundColor(textColor)
                                Text("Once approved, you'll receive an email with a link to finalize your account.")
                                    .font(.subheadline)
                                    .foregroundColor(secondaryTextColor)
                            }
                        }
                        
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "3.circle.fill")
                                .foregroundColor(AppTheme.primaryBlue)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Open Link in App")
                                    .font(.headline)
                                    .foregroundColor(textColor)
                                Text("Tap the link in the email to open this app and complete your setup with a secure seed phrase.")
                                    .font(.subheadline)
                                    .foregroundColor(secondaryTextColor)
                            }
                        }
                    }
                }
                .padding(24)
                .background(cardBackground)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
                .padding(.horizontal)
                
                Spacer()
                
                // Done button
                Button(action: {
                    viewModel.reset()
                    // Dismiss the entire registration flow
                    onDismissAll?()
                }) {
                    HStack {
                        Text("Done")
                        Image(systemName: "checkmark")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.primaryBlue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled()
    }
}
