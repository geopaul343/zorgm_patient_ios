import SwiftUI

// MARK: - Main Tab View
struct MainTabView: View {
    // MARK: - Environment Objects
    @EnvironmentObject private var navigationManager: NavigationManager
    
    // MARK: - Body
    var body: some View {
        TabView(selection: $navigationManager.selectedTab) {
            // Dashboard Tab
            DashboardView()
                .tabItem {
                    Image(systemName: NavigationManager.Tab.dashboard.icon)
                    Text(NavigationManager.Tab.dashboard.rawValue)
                }
                .tag(NavigationManager.Tab.dashboard)
            
            // Assessments Tab
            AssessmentsView()
                .tabItem {
                    Image(systemName: NavigationManager.Tab.assessments.icon)
                    Text(NavigationManager.Tab.assessments.rawValue)
                }
                .tag(NavigationManager.Tab.assessments)
            
            // Medications Tab
            MedicationsView()
                .tabItem {
                    Image(systemName: NavigationManager.Tab.medications.icon)
                    Text(NavigationManager.Tab.medications.rawValue)
                }
                .tag(NavigationManager.Tab.medications)
            
            // History Tab
            HistoryView()
                .tabItem {
                    Image(systemName: NavigationManager.Tab.history.icon)
                    Text(NavigationManager.Tab.history.rawValue)
                }
                .tag(NavigationManager.Tab.history)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Image(systemName: NavigationManager.Tab.settings.icon)
                    Text(NavigationManager.Tab.settings.rawValue)
                }
                .tag(NavigationManager.Tab.settings)
        }
        .accentColor(.blue)
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
        .environmentObject(NavigationManager())
        .environmentObject(SessionManager())
}

