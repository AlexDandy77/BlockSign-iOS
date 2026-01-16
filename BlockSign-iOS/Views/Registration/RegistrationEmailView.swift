import SwiftUI

/// Step 1: Email entry for registration
struct RegistrationEmailView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @FocusState private var isEmailFocused: Bool
    
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
        NavigationStack {
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
                    
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 60))
                                .foregroundColor(AppTheme.primaryBlue)
                                .blur(radius: 15)
                                .opacity(0.5)
                            
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 50))
                                .foregroundColor(AppTheme.primaryBlue)
                        }
                        
                        Text("Create Account")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(textColor)
                        
                        Text("Enter your email to get started")
                            .font(.subheadline)
                            .foregroundColor(secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    // Email input card
                    VStack(spacing: 20) {
                        // Email field
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(AppTheme.primaryBlue)
                            
                            TextField("Email", text: $viewModel.email)
                                .foregroundColor(textColor)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .focused($isEmailFocused)
                                .submitLabel(.continue)
                                .onSubmit {
                                    if viewModel.isEmailValid {
                                        Task { await viewModel.requestOTP() }
                                    }
                                }
                        }
                        .padding()
                        .background(inputBackground)
                        .cornerRadius(12)
                        
                        // Error message
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Continue button
                        Button(action: {
                            Task { await viewModel.requestOTP() }
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Continue")
                                    Image(systemName: "arrow.right")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.isEmailValid ? AppTheme.primaryBlue : Color.gray.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(!viewModel.isEmailValid || viewModel.isLoading)
                    }
                    .padding(24)
                    .background(cardBackground)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Login link
                    Button(action: { dismiss() }) {
                        Text("Already have an account? ")
                            .foregroundColor(secondaryTextColor) +
                        Text("Log in")
                            .foregroundColor(AppTheme.primaryBlue)
                            .fontWeight(.semibold)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(textColor)
                    }
                }
            }
            .navigationDestination(isPresented: Binding(
                get: { viewModel.currentStep == .otp },
                set: { if !$0 { viewModel.goBack() } }
            )) {
                RegistrationOTPView(viewModel: viewModel, onDismissAll: { dismiss() })
            }
            .onAppear {
                isEmailFocused = true
            }
        }
    }
}
