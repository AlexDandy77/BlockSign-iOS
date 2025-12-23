import SwiftUI

struct PersonalCabinetView: View {
    @EnvironmentObject var documentManager: DocumentManager
    
    var body: some View {
        NavigationView {
            DashboardView()
        }
    }
}
