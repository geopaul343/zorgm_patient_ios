import Foundation
import Combine

// MARK: - Assessment Detail View Model
class AssessmentDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var questions: [Question] = []
    @Published var isLoading: Bool = false
    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String?
    @Published var submissionSuccess: Bool = false
    
    // MARK: - Private Properties
    private let apiService = APIService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    @MainActor
    func loadAssessment(type: AssessmentType) async {
        isLoading = true
        errorMessage = nil
        
        apiService.getHealthAssessment(type: type)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    self?.isLoading = false
                    if case .failure(let error) = result {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] response in
                    self?.questions = response.questions.sorted { $0.sequence < $1.sequence }
                }
            )
            .store(in: &cancellables)
    }
    
    @MainActor
    func submitAssessment(answers: [String: String]) async {
        isSubmitting = true
        errorMessage = nil
        
        // Determine assessment type from questions
        guard questions.first != nil else {
            errorMessage = "No questions to submit"
            isSubmitting = false
            return
        }
        
        // This is a simplified approach - in a real app, you'd have the assessment type
        let assessmentType = AssessmentType.daily // This should be passed from the view
        
        apiService.submitAssessment(type: assessmentType, answers: answers)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    self?.isSubmitting = false
                    if case .failure(let error) = result {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] result in
                    self?.isSubmitting = false
                    self?.submissionSuccess = true
                }
            )
            .store(in: &cancellables)
    }
    
    func clearError() {
        errorMessage = nil
    }
}
