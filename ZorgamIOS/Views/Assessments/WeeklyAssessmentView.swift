import SwiftUI
import Combine

// MARK: - Weekly Assessment View
struct WeeklyAssessmentView: View {
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
                ProgressView("Loading weekly assessment...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if allQuestions.isEmpty {
                EmptyStateView(
                    icon: "chart.bar.fill",
                    title: "No Weekly Assessment",
                    message: "Unable to load weekly assessment questions."
                )
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
                        Text("Weekly Check-in")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                // Question Content
                if currentQuestionIndex < allQuestions.count {
                    // Custom UI for specific weekly questions
                    if currentQuestionIndex == 1 {
                        // Question 2: Show range options (0, 1-2, 3-5, 6-7)
                        WeeklyRangeAnswerView(
                            question: allQuestions[currentQuestionIndex],
                            answer: Binding(
                                get: { answers[allQuestions[currentQuestionIndex].key] ?? "" },
                                set: { answers[allQuestions[currentQuestionIndex].key] = $0 }
                            )
                        )
                        .padding(.horizontal, 20)
                    } else if currentQuestionIndex == 2 {
                        // Question 3: Show Yes/No answer box
                        WeeklyYesNoAnswerView(
                            question: allQuestions[currentQuestionIndex],
                            answer: Binding(
                                get: { answers[allQuestions[currentQuestionIndex].key] ?? "" },
                                set: { answers[allQuestions[currentQuestionIndex].key] = $0 }
                            )
                        )
                        .padding(.horizontal, 20)
                    } else {
                        // Default question view for other questions
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
            Text("Your weekly assessment has been submitted successfully!")
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
        
        apiService.getQuestionnaire(type: .weekly)
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

// MARK: - Weekly Range Answer View (Question 2)
struct WeeklyRangeAnswerView: View {
    let question: QuestionnaireQuestion
    @Binding var answer: String
    
    // Define range options for weekly assessment
    private let rangeOptions: [(label: String, value: String)] = [
        ("0", "0"),
        ("1-2", "1-2"),
        ("3-5", "3-5"),
        ("6-7", "6-7")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Question Header
            VStack(alignment: .leading, spacing: 12) {
                Text(question.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                if let subtitle = question.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            
            // Range Options
            VStack(alignment: .leading, spacing: 16) {
                Text("Select your range:")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(spacing: 12) {
                    ForEach(rangeOptions, id: \.value) { option in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                answer = option.value
                            }
                        }) {
                            HStack {
                                Text(option.label)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                ZStack {
                                    Circle()
                                        .stroke(answer == option.value ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                                        .frame(width: 24, height: 24)
                                    
                                    if answer == option.value {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 12, height: 12)
                                    }
                                }
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(answer == option.value ? Color.blue.opacity(0.1) : Color(.systemGray6))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Weekly Yes/No Answer View (Question 3)
struct WeeklyYesNoAnswerView: View {
    let question: QuestionnaireQuestion
    @Binding var answer: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Question Header
            VStack(alignment: .leading, spacing: 12) {
                Text(question.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                if let subtitle = question.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            
            // Yes/No Options
            VStack(alignment: .leading, spacing: 16) {
                Text("Select your answer:")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 20) {
                    // Yes Option
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            answer = "yes"
                        }
                    }) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(answer == "yes" ? Color.blue : Color.gray.opacity(0.2))
                                    .frame(width: 24, height: 24)
                                
                                if answer == "yes" {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            Text("Yes")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(answer == "yes" ? Color.blue.opacity(0.1) : Color(.systemGray6))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // No Option
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            answer = "no"
                        }
                    }) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(answer == "no" ? Color.blue : Color.gray.opacity(0.2))
                                    .frame(width: 24, height: 24)
                                
                                if answer == "no" {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            Text("No")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(answer == "no" ? Color.blue.opacity(0.1) : Color(.systemGray6))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}