import Foundation
import Combine

// MARK: - Assessments View Model
class AssessmentsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var recentActivity: [AssessmentActivity] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let apiService = APIService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    @MainActor
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        // Load recent activity
        await loadRecentActivity()
        
        isLoading = false
    }
    
    @MainActor
    func refreshData() async {
        await loadData()
    }
    
    func isAssessmentCompleted(_ type: AssessmentType) -> Bool {
        // Check if assessment was completed today
        let today = Calendar.current.startOfDay(for: Date())
        return recentActivity.contains { activity in
            activity.type == type && 
            Calendar.current.isDate(activity.completedAt, inSameDayAs: today)
        }
    }
    
    func getLastCompletedDate(_ type: AssessmentType) -> Date? {
        return recentActivity
            .filter { $0.type == type }
            .max { $0.completedAt < $1.completedAt }?
            .completedAt
    }
    
    // MARK: - Private Methods
    private func loadRecentActivity() async {
        // For now, create mock data
        // In a real app, this would come from the API
        recentActivity = [
            AssessmentActivity(type: .daily, completedAt: Date().addingTimeInterval(-3600)),
            AssessmentActivity(type: .weekly, completedAt: Date().addingTimeInterval(-86400)),
            AssessmentActivity(type: .monthly, completedAt: Date().addingTimeInterval(-604800))
        ]
    }
}
