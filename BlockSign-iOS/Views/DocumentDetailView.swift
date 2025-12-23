import SwiftUI
import PDFKit

struct DocumentDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var documentManager: DocumentManager
    let document: Document
    @StateObject var viewModel: DocumentSigningViewModel
    
    @State private var showPDFViewer = false
    
    init(document: Document) {
        self.document = document
        _viewModel = StateObject(wrappedValue: DocumentSigningViewModel(document: document))
    }
    
    // Check if current user is a participant who hasn't signed yet
    private var canSignOrReject: Bool {
        // Must be a participant
        guard document.isParticipant else {
            return false
        }
        
        guard let currentUserId = documentManager.currentUser?.id else {
            return false
        }
        
        // Check if current user has already signed
        let hasAlreadySigned = document.signatures.contains { $0.user.id == currentUserId }
        
        // Check if current user has rejected
        let hasRejected = document.participants.contains { participant in
            participant.user.id == currentUserId && participant.decision == "REJECTED"
        }
        
        // Can sign/reject if we haven't signed and haven't rejected
        return !hasAlreadySigned && !hasRejected
    }
    
    // Compute the correct progress: signatures count vs required participants
    private var signatureProgress: String {
        let requiredCount = document.participants.filter { $0.required }.count + 1
        let signedCount = document.signatures.count
        return "\(signedCount)/\(requiredCount) signed"
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Main Card
                    DocumentDetailCard(document: document, signatureProgress: signatureProgress)
                    
                    // View Document Button
                    ViewDocumentButton(viewModel: viewModel, showPDFViewer: $showPDFViewer)
                    
                    // Action Buttons (only show if user hasn't signed yet)
                    if document.status == .pending && canSignOrReject {
                        ActionButtonsCard(viewModel: viewModel)
                    }
                    
                    if let error = viewModel.error {
                        ErrorCardView(message: error)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Document Details")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.signedSuccessfully) { _, success in
            if success {
                // Refresh documents and go back
                Task {
                    await documentManager.fetchMyDocuments()
                    dismiss()
                }
            }
        }
        .onChange(of: viewModel.rejectedSuccessfully) { _, success in
            if success {
                // Refresh documents and go back
                Task {
                    await documentManager.fetchMyDocuments()
                    dismiss()
                }
            }
        }
        .fullScreenCover(isPresented: $showPDFViewer) {
            if let pdfData = viewModel.documentData {
                PDFViewerView(pdfData: pdfData, documentTitle: document.title)
            }
        }
    }
}

// MARK: - Document Detail Card

struct DocumentDetailCard: View {
    @Environment(\.colorScheme) var colorScheme
    let document: Document
    let signatureProgress: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text(document.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textColor(for: colorScheme))
                
                HStack {
                    DocumentStatusBadge(status: document.status)
                    
                    Spacer()
                    
                    Text(signatureProgress)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                }
                
                Text("Created \(document.createdAt, format: .dateTime.day().month().year())")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
            }
            
            Rectangle()
                .fill(AppTheme.primaryBlue.opacity(0.2))
                .frame(height: 1)
            
            // Owner Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Owner")
                    .font(.headline)
                    .foregroundColor(AppTheme.textColor(for: colorScheme))
                
                HStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundColor(AppTheme.primaryBlue)
                    
                    Text(document.owner.displayName)
                        .font(.body)
                        .foregroundColor(AppTheme.textColor(for: colorScheme))
                }
            }
            
            Rectangle()
                .fill(AppTheme.primaryBlue.opacity(0.2))
                .frame(height: 1)
            
            // Participants Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Participants")
                    .font(.headline)
                    .foregroundColor(AppTheme.textColor(for: colorScheme))
                
                ForEach(document.participants) { participant in
                    DetailParticipantRow(
                        participant: participant,
                        signatures: document.signatures
                    )
                }
            }
            
            Rectangle()
                .fill(AppTheme.primaryBlue.opacity(0.2))
                .frame(height: 1)
            
            // Signatures Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Signatures")
                    .font(.headline)
                    .foregroundColor(AppTheme.textColor(for: colorScheme))
                
                if document.signatures.isEmpty {
                    Text("No signatures yet")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                } else {
                    ForEach(document.signatures) { signature in
                        DetailSignatureRow(signature: signature)
                    }
                }
            }
        }
        .padding()
        .background(AppTheme.cardBackground(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, y: 4)
    }
}

// MARK: - Participant Row

struct DetailParticipantRow: View {
    @Environment(\.colorScheme) var colorScheme
    let participant: DocumentParticipant
    let signatures: [Signature]
    
    private var hasSigned: Bool {
        signatures.contains { $0.user.id == participant.user.id }
    }
    
    var body: some View {
        HStack {
            Image(systemName: "person.fill")
                .foregroundColor(AppTheme.primaryBlue.opacity(0.7))
            
            Text(participant.user.displayName)
                .font(.body)
                .foregroundColor(AppTheme.textColor(for: colorScheme))
            
            if participant.required {
                Text("(required)")
                    .font(.caption)
                    .foregroundColor(AppTheme.warning)
            }
            
            Spacer()
            
            if hasSigned {
                Text("SIGNED")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.success)
            } else if let decision = participant.decision, decision == "REJECTED" {
                Text("REJECTED")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.error)
            } else {
                Text("PENDING")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
            }
        }
    }
}

// MARK: - Signature Row

struct DetailSignatureRow: View {
    @Environment(\.colorScheme) var colorScheme
    let signature: Signature
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.seal.fill")
                .font(.title3)
                .foregroundColor(AppTheme.success)
            
            Text(signature.user.displayName)
                .font(.body)
                .foregroundColor(AppTheme.textColor(for: colorScheme))
            
            Spacer()
            
            Text(signature.signedAt, format: .dateTime.day().month().year())
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
        }
    }
}

// MARK: - Action Buttons Card

struct ActionButtonsCard: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: DocumentSigningViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                Task { await viewModel.signDocument() }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.success)
                        .cornerRadius(12)
                } else {
                    HStack {
                        Image(systemName: "signature")
                        Text("Sign Document")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.success)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: AppTheme.success.opacity(0.4), radius: 8, y: 4)
                }
            }
            .disabled(viewModel.isLoading)
            
            Button(action: {
                Task { await viewModel.rejectDocument(reason: "User rejected") }
            }) {
                HStack {
                    Image(systemName: "xmark.circle")
                    Text("Reject")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.error)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: AppTheme.error.opacity(0.4), radius: 8, y: 4)
            }
            .disabled(viewModel.isLoading)
        }
        .padding()
        .background(AppTheme.cardBackground(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, y: 4)
    }
}

// MARK: - Error Card

struct ErrorCardView: View {
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

// MARK: - View Document Button

struct ViewDocumentButton: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: DocumentSigningViewModel
    @Binding var showPDFViewer: Bool
    
    var body: some View {
        if viewModel.isDocumentExpired {
            // Document expired state
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "clock.badge.xmark")
                    Text("Document Expired")
                }
                .font(.headline)
                .foregroundColor(AppTheme.warning)
                
                Text("The document file is no longer available on the server. Files are stored for 7 days.")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.cardBackground(for: colorScheme))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.warning.opacity(0.5), lineWidth: 2)
            )
        } else {
            Button(action: {
                Task {
                    if viewModel.documentData == nil {
                        await viewModel.fetchDocumentFile()
                    }
                    if viewModel.documentData != nil {
                        showPDFViewer = true
                    }
                }
            }) {
                if viewModel.isLoadingDocument {
                    HStack {
                        ProgressView()
                            .tint(AppTheme.primaryBlue)
                        Text("Loading Document...")
                            .foregroundColor(AppTheme.primaryBlue)
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.cardBackground(for: colorScheme))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.primaryBlue, lineWidth: 2)
                    )
                } else {
                    HStack {
                        Image(systemName: viewModel.documentData != nil ? "doc.text.fill" : "arrow.down.doc")
                        Text(viewModel.documentData != nil ? "View Document" : "Download & View")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.cardBackground(for: colorScheme))
                    .foregroundColor(AppTheme.primaryBlue)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.primaryBlue, lineWidth: 2)
                    )
                    .shadow(color: AppTheme.primaryBlue.opacity(0.2), radius: 8, y: 4)
                }
            }
            .disabled(viewModel.isLoadingDocument)
        }
    }
}

// MARK: - PDF Viewer

struct PDFViewerView: View {
    @Environment(\.dismiss) var dismiss
    let pdfData: Data
    let documentTitle: String
    
    var body: some View {
        NavigationStack {
            PDFKitView(data: pdfData)
                .navigationTitle(documentTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ShareLink(item: pdfData, preview: SharePreview(documentTitle, icon: Image(systemName: "doc.fill"))) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
        }
    }
}

// MARK: - PDFKit UIViewRepresentable

struct PDFKitView: UIViewRepresentable {
    let data: Data
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        if let document = PDFDocument(data: data) {
            pdfView.document = document
        }
    }
}
