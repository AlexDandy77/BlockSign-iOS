import SwiftUI

/// Step 3: User details form for registration
struct RegistrationDetailsView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    var onDismissAll: (() -> Void)? = nil
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case fullName, username, phone, idnp
    }
    
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
                            Image(systemName: "person.text.rectangle")
                                .font(.system(size: 50))
                                .foregroundColor(AppTheme.primaryBlue)
                                .blur(radius: 15)
                                .opacity(0.5)
                            
                            Image(systemName: "person.text.rectangle")
                                .font(.system(size: 40))
                                .foregroundColor(AppTheme.primaryBlue)
                        }
                        
                        Text("Your Details")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(textColor)
                        
                        Text("Fill in your information to complete registration")
                            .font(.subheadline)
                            .foregroundColor(secondaryTextColor)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Form card
                    VStack(spacing: 16) {
                        // Full Name
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Full Name")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(secondaryTextColor)
                            
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(AppTheme.primaryBlue)
                                
                                TextField("John Doe", text: $viewModel.fullName)
                                    .foregroundColor(textColor)
                                    .textContentType(.name)
                                    .focused($focusedField, equals: .fullName)
                                    .submitLabel(.next)
                                    .onSubmit { focusedField = .username }
                            }
                            .padding()
                            .background(inputBackground)
                            .cornerRadius(12)
                        }
                        
                        // Username
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Username")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(secondaryTextColor)
                            
                            HStack {
                                Image(systemName: "at")
                                    .foregroundColor(AppTheme.primaryBlue)
                                
                                TextField("johndoe", text: $viewModel.username)
                                    .foregroundColor(textColor)
                                    .autocapitalization(.none)
                                    .textContentType(.username)
                                    .focused($focusedField, equals: .username)
                                    .submitLabel(.next)
                                    .onSubmit { focusedField = .phone }
                            }
                            .padding()
                            .background(inputBackground)
                            .cornerRadius(12)
                            
                            Text("Letters, numbers, dots, dashes, and underscores only")
                                .font(.caption2)
                                .foregroundColor(secondaryTextColor)
                        }
                        
                        // Phone
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Phone Number")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(secondaryTextColor)
                            
                            HStack {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(AppTheme.primaryBlue)
                                
                                TextField("+373 XX XXX XXX", text: $viewModel.phone)
                                    .foregroundColor(textColor)
                                    .keyboardType(.phonePad)
                                    .textContentType(.telephoneNumber)
                                    .focused($focusedField, equals: .phone)
                            }
                            .padding()
                            .background(inputBackground)
                            .cornerRadius(12)
                        }
                        
                        // IDNP
                        VStack(alignment: .leading, spacing: 6) {
                            Text("IDNP (Personal ID)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(secondaryTextColor)
                            
                            HStack {
                                Image(systemName: "creditcard.fill")
                                    .foregroundColor(AppTheme.primaryBlue)
                                
                                TextField("2000000000000", text: $viewModel.idnp)
                                    .foregroundColor(textColor)
                                    .keyboardType(.numberPad)
                                    .focused($focusedField, equals: .idnp)
                            }
                            .padding()
                            .background(inputBackground)
                            .cornerRadius(12)
                        }
                        
                        // Error message
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                        }
                        
                        // Submit button
                        Button(action: {
                            focusedField = nil
                            Task { await viewModel.submitRequest() }
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Submit Request")
                                    Image(systemName: "paperplane.fill")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.isDetailsValid ? AppTheme.primaryBlue : Color.gray.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(!viewModel.isDetailsValid || viewModel.isLoading)
                        .padding(.top, 8)
                    }
                    .padding(24)
                    .background(cardBackground)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
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
            
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { viewModel.currentStep == .pending },
            set: { _ in }
        )) {
            RegistrationPendingView(viewModel: viewModel, onDismissAll: onDismissAll)
        }
        .onAppear {
            focusedField = .fullName
        }
    }
}
