import SwiftUI

/// Step 2: OTP verification for registration
struct RegistrationOTPView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    var onDismissAll: (() -> Void)? = nil
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var isOTPFocused: Bool
    
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
            
            VStack(spacing: 24) {
                Spacer()
                
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Image(systemName: "envelope.badge.shield.half.filled")
                            .font(.system(size: 60))
                            .foregroundColor(AppTheme.primaryBlue)
                            .blur(radius: 15)
                            .opacity(0.5)
                        
                        Image(systemName: "envelope.badge.shield.half.filled")
                            .font(.system(size: 50))
                            .foregroundColor(AppTheme.primaryBlue)
                    }
                    
                    Text("Verify Email")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(textColor)
                    
                    Text("Enter the 6-digit code sent to")
                        .font(.subheadline)
                        .foregroundColor(secondaryTextColor)
                    
                    Text(viewModel.email)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.primaryBlue)
                }
                
                Spacer()
                
                // OTP input card
                VStack(spacing: 20) {
                    // OTP display boxes
                    HStack(spacing: 8) {
                        ForEach(0..<6, id: \.self) { index in
                            let character = index < viewModel.otpCode.count
                                ? String(viewModel.otpCode[viewModel.otpCode.index(viewModel.otpCode.startIndex, offsetBy: index)])
                                : ""
                            
                            Text(character)
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(textColor)
                                .frame(width: 45, height: 55)
                                .background(inputBackground)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(
                                            index == viewModel.otpCode.count
                                                ? AppTheme.primaryBlue
                                                : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                        }
                    }
                    .overlay(
                        // Hidden text field for actual input
                        TextField("", text: $viewModel.otpCode)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .focused($isOTPFocused)
                            .foregroundColor(.clear)
                            .accentColor(.clear)
                            .onChange(of: viewModel.otpCode) { _, newValue in
                                // Limit to 6 digits
                                if newValue.count > 6 {
                                    viewModel.otpCode = String(newValue.prefix(6))
                                }
                                // Filter non-digits
                                viewModel.otpCode = newValue.filter { $0.isNumber }
                                
                                // Auto-submit when 6 digits entered
                                if viewModel.otpCode.count == 6 {
                                    Task { await viewModel.verifyOTP() }
                                }
                            }
                    )
                    .onTapGesture {
                        isOTPFocused = true
                    }
                    
                    // Error message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Loading indicator (auto-verifies when 6 digits entered)
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryBlue))
                            .padding(.vertical, 8)
                    }
                    
                    // Resend button
                    Button(action: {
                        Task { await viewModel.resendOTP() }
                    }) {
                        Text("Didn't receive the code? ")
                            .foregroundColor(secondaryTextColor) +
                        Text("Resend")
                            .foregroundColor(AppTheme.primaryBlue)
                            .fontWeight(.semibold)
                    }
                    .disabled(viewModel.isLoading)
                }
                .padding(24)
                .background(cardBackground)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { viewModel.goBack() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(AppTheme.primaryBlue)
                }
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { viewModel.currentStep == .details },
            set: { if !$0 { viewModel.goBack() } }
        )) {
            RegistrationDetailsView(viewModel: viewModel, onDismissAll: onDismissAll)
        }
        .onAppear {
            isOTPFocused = true
        }
    }
}
