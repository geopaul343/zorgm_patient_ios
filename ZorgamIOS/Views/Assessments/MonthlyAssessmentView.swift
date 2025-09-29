import SwiftUI
import Combine

// MARK: - Monthly Assessment View
struct MonthlyAssessmentView: View {
    @StateObject private var apiService = APIService()
    @EnvironmentObject private var navigationManager: NavigationManager
    @State private var questionnaires: [Questionnaire] = []
    @State private var answers: [String: String] = [:]
    @State private var isLoading = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    
    // Question flow state
    @State private var currentQuestionIndex = 0
    @State private var allQuestions: [QuestionnaireQuestion] = []
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView("Loading monthly assessment...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if allQuestions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text("No Monthly Assessment")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Unable to load monthly assessment questions.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Progress Header
                VStack(spacing: 16) {
                    // Progress Bar
                    ProgressView(value: Double(currentQuestionIndex + 1), total: Double(allQuestions.count))
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                    
                    // Question Counter
                    HStack {
                        Text("Question \(currentQuestionIndex + 1) of \(allQuestions.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Monthly Check-in")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                // Question Content
                ScrollView {
                    VStack {
                        if currentQuestionIndex < allQuestions.count {
                            QuestionStepView(
                                question: allQuestions[currentQuestionIndex],
                                questionIndex: currentQuestionIndex,
                                answer: Binding(
                                    get: { answers[allQuestions[currentQuestionIndex].key] ?? "" },
                                    set: { answers[allQuestions[currentQuestionIndex].key] = $0 }
                                )
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 20)
                }
                
                Spacer()
                
                // Navigation Buttons
                HStack(spacing: 16) {
                    // Previous Button
                    Button(action: previousQuestion) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Previous")
                        }
                        .foregroundColor(currentQuestionIndex > 0 ? .blue : .gray)
                        .fontWeight(.medium)
                    }
                    .disabled(currentQuestionIndex == 0)
                    
                    Spacer()
                    
                    // Next/Submit Button
                    Button(action: nextQuestion) {
                        HStack {
                            if currentQuestionIndex == allQuestions.count - 1 {
                                if isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                                Text(isSubmitting ? "Submitting..." : "Submit")
                            } else {
                                Text("Next")
                                Image(systemName: "chevron.right")
                            }
                        }
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            isCurrentQuestionAnswered ? 
                            (isSubmitting ? Color.gray : Color.blue) : 
                            Color.gray.opacity(0.3)
                        )
                        .cornerRadius(25)
                    }
                    .disabled(!isCurrentQuestionAnswered || isSubmitting)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            loadQuestionnaire()
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK") {
                // Reset form and navigate to dashboard
                answers.removeAll()
                navigationManager.navigateToTab(.dashboard)
            }
        } message: {
            Text("Your monthly assessment has been submitted successfully!")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "Failed to submit assessment. Please try again.")
        }
        .onTapGesture {
            // Hide keyboard when tapping anywhere
            hideKeyboard()
        }
    }
    
    // MARK: - Computed Properties
    private var isCurrentQuestionAnswered: Bool {
        guard currentQuestionIndex < allQuestions.count else { return false }
        let currentQuestion = allQuestions[currentQuestionIndex]
        let answer = answers[currentQuestion.key] ?? ""
        return !answer.isEmpty
    }
    
    private var isFormValid: Bool {
        // Check if all required questions are answered
        for question in allQuestions {
            if question.isRequired && (answers[question.key]?.isEmpty ?? true) {
                return false
            }
        }
        return !allQuestions.isEmpty
    }
    
    // MARK: - Navigation Methods
    private func nextQuestion() {
        if currentQuestionIndex == allQuestions.count - 1 {
            // Last question - submit
            submitAnswers()
        } else {
            // Move to next question
            withAnimation(.easeInOut(duration: 0.3)) {
                currentQuestionIndex += 1
            }
        }
    }
    
    private func previousQuestion() {
        if currentQuestionIndex > 0 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentQuestionIndex -= 1
            }
        }
    }
    
    private func loadQuestionnaire() {
        isLoading = true
        errorMessage = nil
        
        apiService.getQuestionnaire(type: .monthly)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                        print("❌ Failed to load questionnaire: \(error)")
                    }
                },
                receiveValue: { questionnaires in
                    self.questionnaires = questionnaires
                    // Extract all questions and sort by sequence
                    self.allQuestions = questionnaires.flatMap { $0.questions }.sorted { $0.sequence < $1.sequence }
                    print("✅ Loaded \(questionnaires.count) questionnaires with \(self.allQuestions.count) questions")
                }
            )
            .store(in: &cancellables)
    }
    
    private func submitAnswers() {
        guard let questionnaire = questionnaires.first else { return }
        
        isSubmitting = true
        
        let submission = QuestionnaireSubmission(
            questionnaireId: questionnaire.id,
            answersJson: answers,
            status: "completed"
        )
        
        apiService.submitQuestionnaire(submission: submission)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isSubmitting = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                        showErrorAlert = true
                        print("❌ Failed to submit questionnaire: \(error)")
                    }
                },
                receiveValue: { response in
                    print("✅ Questionnaire submitted successfully: \(response.id)")
                    showSuccessAlert = true
                    
                    // Post notification to trigger confetti animation
                    NotificationCenter.default.post(name: .assessmentSubmittedSuccessfully, object: nil)
                }
            )
            .store(in: &cancellables)
    }
    
    @State private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Helper Functions
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}