import SwiftUI

@main
struct BlockSign_iOSApp: App {
    @StateObject var authManager = AuthenticationManager()
    @StateObject var documentManager = DocumentManager()
    
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
