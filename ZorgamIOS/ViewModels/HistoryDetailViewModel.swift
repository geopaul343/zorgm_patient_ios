import Foundation
import Combine

// MARK: - History Detail View Model
class HistoryDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var answers: [QuestionAnswer] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let apiService = APIService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    @MainActor
    func loadDetailData(submission: SubmissionResponses) async {
        isLoading = true
        errorMessage = nil
        
        // Fetch specific questionnaire by ID and checkin type
        apiService.getQuestionnaireById(questionnaireId: submission.questionnaireId, checkinType: submission.checkinType)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                        print("❌ Failed to load questionnaire: \(error)")
                    }
                },
                receiveValue: { [weak self] questionnaires in
                    guard let self = self else { return }
                    
                    // Extract all questions from questionnaires
                    let allQuestions = questionnaires.flatMap { $0.questions }
                    
                    // Create history detail with questions and answers matched by ID
                    let historyDetail = HistoryDetail(from: submission, questions: allQuestions)
                    self.answers = historyDetail.answers
                    
                    print("✅ Loaded \(self.answers.count) question-answer pairs for submission \(submission.id) with questionnaire ID: \(submission.questionnaireId)")
                }
            )
            .store(in: &cancellables)
    }
    
    @MainActor
    func refreshData() async {
        // This could be used to refresh the data if needed
        // For now, we'll just clear and reload
        answers = []
    }
    
    // MARK: - Private Methods
    private func determineAssessmentType(from checkinType: String) -> AssessmentType {
        switch checkinType.uppercased() {
        case "DAILY":
            return .daily
        case "WEEKLY":
            return .weekly
        case "MONTHLY":
            return .monthly
        default:
            return .weekly // Default fallback
        }
    }
}
