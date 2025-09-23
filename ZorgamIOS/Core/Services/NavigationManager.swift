import SwiftUI
import Combine

// MARK: - Navigation Manager
class NavigationManager: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedTab: Tab = .dashboard
    @Published var navigationPath = NavigationPath()
    @Published var selectedAssessmentType: AssessmentType? = nil
    
    // MARK: - Tab Enum
    enum Tab: String, CaseIterable {
        case dashboard = "Dashboard"
        case assessments = "Assessments"
        case medications = "Medications"
        case history = "History"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .dashboard: return "house.fill"
            case .assessments: return "checkmark.circle.fill"
            case .medications: return "pills.fill"
            case .history: return "clock.fill"
            case .settings: return "gear"
            }
        }
    }
    
    // MARK: - Navigation Methods
    func navigateToTab(_ tab: Tab) {
        selectedTab = tab
        // Clear assessment type when switching tabs
        if tab != .assessments {
            selectedAssessmentType = nil
        }
    }
    
    func navigateToAssessment(_ type: AssessmentType) {
        selectedTab = .assessments
        selectedAssessmentType = type
    }
    
    func navigateToMedications() {
        selectedTab = .medications
    }
    
    func navigateToHistory() {
        selectedTab = .history
    }
    
    func navigateToSettings() {
        selectedTab = .settings
    }
    
    func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    func navigateToRoot() {
        navigationPath = NavigationPath()
    }
}
