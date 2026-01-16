import SwiftUI

// Make String identifiable for fullScreenCover(item:)
extension String: @retroactive Identifiable {
    public var id: String { self }
}

@main
struct BlockSign_iOSApp: App {
    @StateObject var authManager = AuthenticationManager()
    @StateObject var documentManager = DocumentManager()
    
    // Deep link state
    @State private var registrationToken: String?
    
    init() {
        // Observe auth state changes to clear document manager on logout
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                switch authManager.state {
                case .authenticated:
                    // User is fully authenticated - show main app
                    TabView {
                        PersonalCabinetView()
                            .environmentObject(documentManager)
                            .environmentObject(authManager)
                            .tabItem {
                                Label("Cabinet", systemImage: "folder.fill")
                            }
                        
                        VerifyDocumentView()
                            .tabItem {
                                Label("Verify", systemImage: "checkmark.seal")
                            }
                        
                        SettingsView()
                            .environmentObject(authManager)
                            .tabItem {
                                Label("Settings", systemImage: "gear")
                            }
                    }
                    
                case .unknown:
                    // Checking stored credentials - show loading
                    LoadingView()
                    
                default:
                    // All other states - show login flow
                    LoginView()
                        .environmentObject(authManager)
                }
            }
            .animation(.easeInOut, value: authManager.state)
            .onChange(of: authManager.state) { oldState, newState in
                // Clear document manager when logging out
                if case .authenticated = oldState, case .authenticated = newState {
                    // Still authenticated, do nothing
                } else if case .authenticated = oldState {
                    // Transitioning away from authenticated state (logout)
                    documentManager.clearState()
                }
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
            .fullScreenCover(item: $registrationToken) { token in
                RegistrationCompleteView(
                    token: token,
                    onComplete: {
                        registrationToken = nil
                        // Optionally trigger login flow after successful registration
                    },
                    onDismiss: {
                        registrationToken = nil
                    }
                )
            }
        }
    }
    
    /// Handle deep links from email (blocksign://complete-registration?token=XXX)
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "blocksign" else { return }
        
        if url.host == "complete-registration" {
            // Parse token from query parameters
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let queryItems = components.queryItems,
               let token = queryItems.first(where: { $0.name == "token" })?.value {
                registrationToken = token
            }
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "signature")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("BlockSign")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            ProgressView()
                .padding()
        }
    }
}
