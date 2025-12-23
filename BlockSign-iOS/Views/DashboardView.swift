import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var documentManager: DocumentManager
    @Environment(\.colorScheme) var colorScheme
    @State private var showingCreateDocument = false
    
    var body: some View {
        ZStack {
            // Themed background
            AppTheme.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    if documentManager.isLoading {
                        ProgressView()
                            .tint(AppTheme.primaryBlue)
                            .padding(.top, 50)
                    } else if documentManager.documents.isEmpty {
                        EmptyDocumentsView()
                    } else {
                        // Card container for all documents
                        VStack(spacing: 0) {
                            ForEach(Array(documentManager.documents.enumerated()), id: \.element.id) { index, doc in
                                NavigationLink(destination: DocumentDetailView(document: doc)) {
                                    DocumentRowView(document: doc)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Add divider between items, but not after the last one
                                if index < documentManager.documents.count - 1 {
                                    Divider()
                                        .background(AppTheme.primaryBlue.opacity(0.2))
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                        .background(AppTheme.cardBackground(for: colorScheme))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, y: 4)
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 8)
            }
        }
        .navigationTitle("My Documents")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingCreateDocument = true }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(AppTheme.primaryBlue)
                }
            }
        }
        .sheet(isPresented: $showingCreateDocument) {
            CreateDocumentView()
        }
        .refreshable {
            await documentManager.fetchMyDocuments()
        }
        .onAppear {
            // Always fetch on appear to ensure we have current user data
            if documentManager.currentUser == nil {
                Task {
                    await documentManager.fetchMyDocuments()
                }
            }
        }
    }
}

// MARK: - Document Row View

struct DocumentRowView: View {
    @Environment(\.colorScheme) var colorScheme
    let document: Document
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(document.title)
                    .font(.headline)
                    .foregroundColor(AppTheme.textColor(for: colorScheme))
                
                DocumentStatusBadge(status: document.status)
            }
            
            Spacer()
            
            Text(document.createdAt, format: .dateTime.day().month().year())
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppTheme.primaryBlue.opacity(0.6))
        }
        .padding(16)
    }
}

// MARK: - Document Status Badge

struct DocumentStatusBadge: View {
    let status: DocStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(6)
    }
    
    var backgroundColor: Color {
        switch status {
        case .pending: return AppTheme.warning
        case .signed: return AppTheme.success
        case .rejected: return AppTheme.error
        }
    }
}

// MARK: - Empty State View

struct EmptyDocumentsView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Image(systemName: "doc.text")
                    .font(.system(size: 60))
                    .foregroundColor(AppTheme.primaryBlue)
                    .blur(radius: 15)
                    .opacity(0.4)
                
                Image(systemName: "doc.text")
                    .font(.system(size: 50))
                    .foregroundColor(AppTheme.primaryBlue)
            }
            
            Text("No Documents")
                .font(.headline)
                .foregroundColor(AppTheme.textColor(for: colorScheme))
            
            Text("Tap the + button to create your first document")
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }
}
