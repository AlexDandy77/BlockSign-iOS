import SwiftUI
import UniformTypeIdentifiers

struct VerifyDocumentView: View {
    @StateObject var viewModel = DocumentVerificationViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var showFileImporter = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Select Document Button
                        Button(action: { showFileImporter = true }) {
                            VStack(spacing: 12) {
                                ZStack {
                                    Image(systemName: "doc.text.magnifyingglass")
                                        .font(.system(size: 60))
                                        .foregroundColor(AppTheme.primaryBlue)
                                        .blur(radius: 15)
                                        .opacity(0.4)
                                    
                                    Image(systemName: "doc.text.magnifyingglass")
                                        .font(.system(size: 50))
                                        .foregroundColor(AppTheme.primaryBlue)
                                }
                                
                                Text("Select Document to Verify")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.primaryBlue)
                            }
                            .padding(.vertical, 30)
                            .frame(maxWidth: .infinity)
                            .background(AppTheme.cardBackground(for: colorScheme))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, y: 4)
                        }
                        .padding(.horizontal)
                        
                        if viewModel.isLoading {
                            ProgressView("Verifying document...")
                                .tint(AppTheme.primaryBlue)
                                .foregroundColor(AppTheme.textColor(for: colorScheme))
                                .padding()
                        }
                        
                        if let error = viewModel.error {
                            VerifyErrorCard(message: error)
                                .padding(.horizontal)
                        }
                        
                        if let result = viewModel.verificationResult {
                            VerificationResultCard(result: result)
                                .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Verify")
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                do {
                    guard let selectedFile: URL = try result.get().first else { return }
                    if selectedFile.startAccessingSecurityScopedResource() {
                        viewModel.selectedFile = selectedFile
                        Task { await viewModel.verifyDocument() }
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - Verification Result Card

struct VerificationResultCard: View {
    @Environment(\.colorScheme) var colorScheme
    let result: VerificationResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with Status
            HStack {
                Image(systemName: result.matched ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(result.matched ? AppTheme.success : AppTheme.error)
                
                Text("Verification Results")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textColor(for: colorScheme))
                
                Spacer()
            }
            
            // Status Badge
            HStack {
                Text("Verification Status:")
                    .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                
                StatusBadgeView(matched: result.matched)
            }
            
            Rectangle()
                .fill(AppTheme.primaryBlue.opacity(0.2))
                .frame(height: 1)
            
            // Document Hash
            VStack(alignment: .leading, spacing: 8) {
                Label("Document Hash (SHA-256):", systemImage: "doc.text")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                
                Text(result.sha256)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(AppTheme.textColor(for: colorScheme))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.inputBackground(for: colorScheme))
                    .cornerRadius(8)
                
                Text("This unique hash identifies your document and ensures its integrity")
                    .font(.caption2)
                    .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
            }
            
            if result.matched, let doc = result.document {
                Rectangle()
                    .fill(AppTheme.primaryBlue.opacity(0.2))
                    .frame(height: 1)
                
                // Document Details
                DocumentDetailsSection(document: doc)
                
                // Participants
                if !doc.participants.isEmpty {
                    Rectangle()
                        .fill(AppTheme.primaryBlue.opacity(0.2))
                        .frame(height: 1)
                    ParticipantsSection(participants: doc.participants)
                }
                
                // Signatures
                if !doc.signatures.isEmpty {
                    Rectangle()
                        .fill(AppTheme.primaryBlue.opacity(0.2))
                        .frame(height: 1)
                    SignaturesSection(signatures: doc.signatures)
                }
                
                // Blockchain
                if let blockchain = doc.blockchain {
                    Rectangle()
                        .fill(AppTheme.primaryBlue.opacity(0.2))
                        .frame(height: 1)
                    BlockchainSection(blockchain: blockchain)
                }
            } else if !result.matched {
                Rectangle()
                    .fill(AppTheme.primaryBlue.opacity(0.2))
                    .frame(height: 1)
                NotFoundSection()
            }
        }
        .padding()
        .background(AppTheme.cardBackground(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, y: 4)
    }
}

// MARK: - Status Badge

struct StatusBadgeView: View {
    let matched: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: matched ? "checkmark.circle" : "xmark.circle")
                .font(.caption)
            Text(matched ? "VERIFIED" : "NOT FOUND")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(matched ? AppTheme.success.opacity(0.2) : AppTheme.error.opacity(0.2))
        .foregroundColor(matched ? AppTheme.success : AppTheme.error)
        .cornerRadius(20)
    }
}

// MARK: - Document Details Section

struct DocumentDetailsSection: View {
    @Environment(\.colorScheme) var colorScheme
    let document: VerifiedDocument
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 20) {
                // Title
                VStack(alignment: .leading, spacing: 4) {
                    Label("Document Title", systemImage: "doc.text")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                    Text(document.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.textColor(for: colorScheme))
                }
                
                Spacer()
                
                // Created Date
                VStack(alignment: .trailing, spacing: 4) {
                    Label("Created Date", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                    Text(document.createdAt, style: .date)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor(for: colorScheme))
                    Text(document.createdAt, style: .time)
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                }
            }
            
            // Owner
            VStack(alignment: .leading, spacing: 4) {
                Label("Document Owner", systemImage: "person.circle")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                
                Text(document.owner.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.textColor(for: colorScheme))
                
                if let username = document.owner.username {
                    Text("@\(username)")
                        .font(.caption)
                        .foregroundColor(AppTheme.primaryBlue)
                }
                
                if let email = document.owner.email {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                }
            }
        }
    }
}

// MARK: - Participants Section

struct ParticipantsSection: View {
    @Environment(\.colorScheme) var colorScheme
    let participants: [DocumentParticipant]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Participants (\(participants.count))", systemImage: "person.2")
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
            
            ForEach(participants) { participant in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(participant.user.displayName)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textColor(for: colorScheme))
                        
                        if let username = participant.user.username {
                            Text("@\(username)")
                                .font(.caption)
                                .foregroundColor(AppTheme.primaryBlue)
                        }
                    }
                    
                    Spacer()
                    
                    if participant.required {
                        Text("Required")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppTheme.warning.opacity(0.2))
                            .foregroundColor(AppTheme.warning)
                            .cornerRadius(4)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - Signatures Section

struct SignaturesSection: View {
    @Environment(\.colorScheme) var colorScheme
    let signatures: [Signature]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Digital Signatures (\(signatures.count))", systemImage: "signature")
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
            
            ForEach(signatures) { signature in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(signature.user.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(AppTheme.textColor(for: colorScheme))
                            
                            if let username = signature.user.username {
                                Text("@\(username)")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.primaryBlue)
                            }
                            
                            Text("Algorithm: \(signature.alg)")
                                .font(.caption2)
                                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                            Text(signature.signedAt, style: .date)
                                .font(.caption)
                                .foregroundColor(AppTheme.textColor(for: colorScheme))
                            Text(signature.signedAt, style: .time)
                                .font(.caption2)
                                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                        }
                    }
                }
                .padding(10)
                .background(AppTheme.inputBackground(for: colorScheme))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Blockchain Section

struct BlockchainSection: View {
    @Environment(\.colorScheme) var colorScheme
    let blockchain: BlockchainInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Blockchain Verification", systemImage: "link")
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Network")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                        Text(blockchain.network)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.textColor(for: colorScheme))
                    }
                    
                    Spacer()
                    
                    if let anchoredAt = blockchain.anchoredAt {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Anchored At")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                            Text(anchoredAt, style: .date)
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textColor(for: colorScheme))
                            Text(anchoredAt, style: .time)
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Transaction ID")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                    
                    Text(blockchain.txId)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(AppTheme.textColor(for: colorScheme))
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.inputBackground(for: colorScheme))
                        .cornerRadius(6)
                }
                
                if let explorerUrl = blockchain.explorerUrl, let url = URL(string: explorerUrl) {
                    Link(destination: url) {
                        HStack {
                            Image(systemName: "link")
                            Text("View on Blockchain Explorer")
                        }
                        .font(.subheadline)
                        .foregroundColor(AppTheme.primaryBlue)
                    }
                }
            }
            .padding()
            .background(AppTheme.inputBackground(for: colorScheme))
            .cornerRadius(10)
        }
    }
}

// MARK: - Not Found Section

struct NotFoundSection: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This document was not found in our system. This could mean:")
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
            
            VStack(alignment: .leading, spacing: 8) {
                BulletPoint(text: "The document has not been uploaded to BlockSign")
                BulletPoint(text: "The document has been modified since it was uploaded")
                BulletPoint(text: "The document was deleted from the system")
            }
        }
        .padding()
        .background(AppTheme.inputBackground(for: colorScheme))
        .cornerRadius(10)
    }
}

struct BulletPoint: View {
    @Environment(\.colorScheme) var colorScheme
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
            Text(text)
                .font(.caption)
                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
        }
    }
}

// MARK: - Verify Error Card

struct VerifyErrorCard: View {
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(AppTheme.error)
            Text(message)
                .font(.subheadline)
                .foregroundColor(AppTheme.error)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.error.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.error.opacity(0.3), lineWidth: 1)
        )
    }
}
