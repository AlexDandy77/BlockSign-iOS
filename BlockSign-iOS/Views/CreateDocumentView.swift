import SwiftUI
import UniformTypeIdentifiers

struct CreateDocumentView: View {
    @StateObject var viewModel = DocumentCreationViewModel()
    @EnvironmentObject var documentManager: DocumentManager
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var showFileImporter = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Document Info Section
                        CreateDocumentCard {
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeaderView(title: "Document Info", icon: "doc.text.fill")
                                
                                // Title Field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Title")
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                                    
                                    TextField("Enter document title", text: $viewModel.documentTitle)
                                        .padding()
                                        .background(AppTheme.inputBackground(for: colorScheme))
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(AppTheme.primaryBlue.opacity(0.3), lineWidth: 1)
                                        )
                                        .foregroundColor(AppTheme.textColor(for: colorScheme))
                                }
                                
                                // File Selection
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("PDF File")
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                                    
                                    Button(action: { showFileImporter = true }) {
                                        HStack {
                                            Image(systemName: "doc.badge.plus")
                                                .font(.title2)
                                                .foregroundColor(AppTheme.primaryBlue)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(viewModel.selectedFile != nil ? "Selected File" : "Select PDF File")
                                                    .font(.headline)
                                                    .foregroundColor(AppTheme.textColor(for: colorScheme))
                                                
                                                if let url = viewModel.selectedFile {
                                                    Text(url.lastPathComponent)
                                                        .font(.caption)
                                                        .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                                                        .lineLimit(1)
                                                } else {
                                                    Text("Tap to browse files")
                                                        .font(.caption)
                                                        .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                                        }
                                        .padding()
                                        .background(AppTheme.inputBackground(for: colorScheme))
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(viewModel.selectedFile != nil ? AppTheme.success.opacity(0.5) : AppTheme.primaryBlue.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }
                        
                        // Participants Section
                        CreateDocumentCard {
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeaderView(title: "Participants", icon: "person.2.fill")
                                
                                // Existing Participants
                                if !viewModel.participants.isEmpty {
                                    ForEach(viewModel.participants, id: \.self) { participant in
                                        ParticipantRow(
                                            email: participant,
                                            onDelete: { viewModel.removeParticipant(participant) }
                                        )
                                    }
                                }
                                
                                // Add Participant
                                HStack(spacing: 12) {
                                    Image(systemName: "person.badge.plus")
                                        .foregroundColor(AppTheme.primaryBlue)
                                    
                                    TextField("Add participant email", text: $viewModel.newParticipant)
                                        .autocapitalization(.none)
                                        .textContentType(.emailAddress)
                                        .keyboardType(.emailAddress)
                                        .foregroundColor(AppTheme.textColor(for: colorScheme))
                                    
                                    Button(action: viewModel.addParticipant) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(viewModel.newParticipant.isEmpty ? AppTheme.secondaryTextColor(for: colorScheme) : AppTheme.primaryBlue)
                                    }
                                    .disabled(viewModel.newParticipant.isEmpty)
                                }
                                .padding()
                                .background(AppTheme.inputBackground(for: colorScheme))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(AppTheme.primaryBlue.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        
                        // Error Message
                        if let error = viewModel.error {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(AppTheme.error)
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.error)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppTheme.error.opacity(0.1))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AppTheme.error.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        // Create Button
                        Button(action: {
                            Task {
                                await viewModel.createDocument()
                                if viewModel.isSuccess {
                                    await documentManager.fetchMyDocuments()
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "signature")
                                    Text("Create & Sign")
                                }
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                AppTheme.buttonGradient(isEnabled: !viewModel.documentTitle.isEmpty && viewModel.selectedFile != nil)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: AppTheme.primaryBlue.opacity(viewModel.documentTitle.isEmpty || viewModel.selectedFile == nil ? 0 : 0.4), radius: 8, y: 4)
                        }
                        .disabled(viewModel.documentTitle.isEmpty || viewModel.selectedFile == nil || viewModel.isLoading)
                        
                        Spacer(minLength: 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("New Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppTheme.primaryBlue)
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                do {
                    guard let selectedFile: URL = try result.get().first else { return }
                    if selectedFile.startAccessingSecurityScopedResource() {
                        viewModel.selectedFile = selectedFile
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - Section Header

struct SectionHeaderView: View {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.primaryBlue)
            Text(title)
                .font(.headline)
                .foregroundColor(AppTheme.textColor(for: colorScheme))
        }
    }
}

// MARK: - Create Document Card

struct CreateDocumentCard<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(AppTheme.cardBackground(for: colorScheme))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, y: 4)
    }
}

// MARK: - Participant Row

struct ParticipantRow: View {
    @Environment(\.colorScheme) var colorScheme
    let email: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundColor(AppTheme.accentBlue)
            
            Text(email)
                .font(.body)
                .foregroundColor(AppTheme.textColor(for: colorScheme))
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .foregroundColor(AppTheme.error)
            }
        }
        .padding()
        .background(AppTheme.inputBackground(for: colorScheme))
        .cornerRadius(10)
    }
}
