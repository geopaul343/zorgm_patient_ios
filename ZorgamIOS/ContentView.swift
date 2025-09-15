import SwiftUI

struct ContentView: View {
    // MARK: - Environment Objects
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var navigationManager: NavigationManager
    
    // MARK: - Body
    var body: some View {
        Group {
            if sessionManager.isLoggedIn {
                MainTabView()
            } else {
                WelcomeView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: sessionManager.isLoggedIn)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environmentObject(SessionManager())
        .environmentObject(NavigationManager())
}
