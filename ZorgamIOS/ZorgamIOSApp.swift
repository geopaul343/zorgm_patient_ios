import SwiftUI

@main
struct ZorgamIOSApp: App {
    // MARK: - Properties
    @StateObject private var sessionManager = SessionManager()
    @StateObject private var navigationManager = NavigationManager()
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionManager)
                .environmentObject(navigationManager)
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .onAppear {
                    // Initialize app services
                    setupApp()
                }
        }
    }
    
    // MARK: - Private Methods
    private func setupApp() {
        // Configure app-wide settings
        configureAppearance()
        
        // Initialize services
        sessionManager.initialize()
    }
    
    private func configureAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.blue.opacity(0.1))
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
}
