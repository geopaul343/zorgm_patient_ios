import SwiftUI
import Combine

// MARK: - Notification Names
extension Notification.Name {
    static let assessmentSubmittedSuccessfully = Notification.Name("assessmentSubmittedSuccessfully")
}

// MARK: - Daily Assessment View
struct DailyAssessmentView: View {
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
    @State private var hasAcknowledged = false
    
    var body: some View {
        VStack(spacing: 0) {
                if isLoading {
                    ProgressView("Loading daily assessment...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if allQuestions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("No Daily Assessment")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Unable to load daily assessment questions.")
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
                        Text("Daily Check-in")
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
                            if currentQuestionIndex == 0 {
                                // First question - show acknowledgment
                                AcknowledgmentQuestionView(
                                    hasAcknowledged: $hasAcknowledged,
                                    question: allQuestions[currentQuestionIndex]
                                )
                                .padding(.horizontal, 20)
                            } else {
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
                    }
                    .padding(.bottom, 20)
                }
                
                Spacer()
                
                // Navigation Buttons
                HStack(spacing: 16) {
                    // Previous Button (only show if not on first question)
                    if currentQuestionIndex > 0 {
                        Button(action: previousQuestion) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Previous")
                            }
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                        }
                    }
                    
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
                // Reset everything when view appears
                resetAssessment()
                loadQuestionnaire()
            }
               .alert("Success", isPresented: $showSuccessAlert) {
                   Button("OK") {
                       // Reset form and navigate to dashboard
                       resetAssessment()
                       navigationManager.navigateToTab(.dashboard)
                   }
               } message: {
                   Text("Your daily assessment has been submitted successfully!")
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
        
        if currentQuestionIndex == 0 {
            // First question only requires acknowledgment
            return hasAcknowledged
        } else {
            // Regular questions
            let currentQuestion = allQuestions[currentQuestionIndex]
            let answer = answers[currentQuestion.key] ?? ""
            return !answer.isEmpty
        }
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
    
    private func resetAssessment() {
        // Reset all state variables
        currentQuestionIndex = 0
        allQuestions = []
        answers.removeAll()
        hasAcknowledged = false
        isLoading = false
        errorMessage = nil
        showSuccessAlert = false
        showErrorAlert = false
        isSubmitting = false
        
        print("🔄 Assessment reset - starting from question 1")
    }
    
    private func loadQuestionnaire() {
        isLoading = true
        errorMessage = nil
        
        apiService.getQuestionnaire(type: .daily)
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

// MARK: - Question Step View
struct QuestionStepView: View {
    let question: QuestionnaireQuestion
    let questionIndex: Int
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
            
            // Answer Options
            VStack(spacing: 16) {
                // Debug: Print question details
                let _ = print("🔍 Question Type: '\(question.questionType)', Options: \(question.options.map { $0.label })")
                
                // TEMPORARY: Force Yes/No for second question (index 1) for testing
                if questionIndex == 1 {
                    let _ = print("🧪 FORCING Yes/No UI for second question (testing)")
                    YesNoAnswerView(answer: $answer)
                }
                // TEMPORARY: Force Color selection for third question (index 2) for testing
                else if questionIndex == 2 {
                    let _ = print("🎨 FORCING Color selection UI for third question (testing)")
                    ColorSelectionAnswerView(question: question, answer: $answer)
                }
                // TEMPORARY: Force Frequency selection for fourth question (index 3) for testing
                else if questionIndex == 3 {
                    let _ = print("🔢 FORCING Frequency selection UI for fourth question (testing)")
                    FrequencySelectionAnswerView(question: question, answer: $answer)
                }
                // TEMPORARY: Force Breathlessness severity for fifth question (index 4) for testing
                else if questionIndex == 4 {
                    let _ = print("🫁 FORCING Breathlessness severity UI for fifth question (testing)")
                    BreathlessnessSeverityAnswerView(question: question, answer: $answer)
                }
                // Check for Yes/No questions first
                else if question.questionType == "boolean" || 
                   question.questionType == "yes_no" || 
                   (question.options.count == 2 && 
                    question.options.contains { $0.label.lowercased() == "yes" } &&
                    question.options.contains { $0.label.lowercased() == "no" }) {
                    // Yes/No Question with beautiful tick boxes
                    let _ = print("✅ Showing Yes/No UI for question: \(question.title)")
                    YesNoAnswerView(answer: $answer)
                } else {
                    // Handle other question types
                    switch QuestionnaireQuestionType(rawValue: question.questionType) {
                    case .singleChoice:
                        SingleChoiceAnswerView(question: question, answer: $answer)
                        
                    case .multipleChoice:
                        MultipleChoiceAnswerView(question: question, answer: $answer)
                        
                    case .text:
                        TextAnswerView(answer: $answer)
                        
                    case .number:
                        NumberAnswerView(answer: $answer)
                        
                    default:
                        TextAnswerView(answer: $answer)
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

// MARK: - Yes/No Answer View
struct YesNoAnswerView: View {
    @Binding var answer: String
    
    var body: some View {
        HStack(spacing: 20) {
            // Yes Option
            Button(action: { answer = "yes" }) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(answer == "yes" ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)
                        
                        if answer == "yes" {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text("Yes")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(answer == "yes" ? .blue : .primary)
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
            Button(action: { answer = "no" }) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(answer == "no" ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)
                        
                        if answer == "no" {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text("No")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(answer == "no" ? .blue : .primary)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(answer == "no" ? Color.blue.opacity(0.1) : Color(.systemGray6))
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Single Choice Answer View
struct SingleChoiceAnswerView: View {
    let question: QuestionnaireQuestion
    @Binding var answer: String
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(question.options) { option in
                Button(action: { answer = option.value }) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(answer == option.value ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                                .frame(width: 24, height: 24)
                            
                            if answer == option.value {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Text(option.label)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(answer == option.value ? .blue : .primary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
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

// MARK: - Multiple Choice Answer View
struct MultipleChoiceAnswerView: View {
    let question: QuestionnaireQuestion
    @Binding var answer: String
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(question.options) { option in
                Button(action: { toggleMultipleChoiceAnswer(option.value) }) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isOptionSelected(option.value) ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                                .frame(width: 24, height: 24)
                            
                            if isOptionSelected(option.value) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Text(option.label)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(isOptionSelected(option.value) ? .blue : .primary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isOptionSelected(option.value) ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private func isOptionSelected(_ value: String) -> Bool {
        return answer.components(separatedBy: ",").contains(value)
    }
    
    private func toggleMultipleChoiceAnswer(_ value: String) {
        let currentAnswers = answer.components(separatedBy: ",").filter { !$0.isEmpty }
        
        if currentAnswers.contains(value) {
            let newAnswers = currentAnswers.filter { $0 != value }
            answer = newAnswers.joined(separator: ",")
        } else {
            let newAnswers = currentAnswers + [value]
            answer = newAnswers.joined(separator: ",")
        }
    }
}

// MARK: - Text Answer View
struct TextAnswerView: View {
    @Binding var answer: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Enter your answer", text: $answer)
                .font(.body)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - Number Answer View
struct NumberAnswerView: View {
    @Binding var answer: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Enter number", text: $answer)
                .font(.body)
                .keyboardType(.numberPad)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - Acknowledgment Question View
struct AcknowledgmentQuestionView: View {
    @Binding var hasAcknowledged: Bool
    let question: QuestionnaireQuestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Question from API
            VStack(alignment: .leading, spacing: 16) {
                Text(question.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                if let subtitle = question.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            
            // Acknowledgment Checkbox
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    hasAcknowledged.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(hasAcknowledged ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)
                        
                        if hasAcknowledged {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text("Acknowledge and agree")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(hasAcknowledged ? Color.blue.opacity(0.1) : Color(.systemGray6))
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Empty State View
private struct DailyDailyEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Color Selection Answer View
struct ColorSelectionAnswerView: View {
    let question: QuestionnaireQuestion
    @Binding var answer: String
    
    // Define available colors
    private let colors: [(name: String, color: Color)] = [
        ("Red", .red),
        ("Orange", .orange),
        ("Yellow", .yellow),
        ("Green", .green),
        ("Blue", .blue),
        ("Purple", .purple),
        ("Pink", .pink),
        ("Brown", .brown),
        ("Gray", .gray),
        ("Black", .black)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select a color:")
                .font(.headline)
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(colors, id: \.name) { colorOption in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                answer = colorOption.name.lowercased()
                            }
                        }) {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(colorOption.color)
                                        .frame(width: 60, height: 60)
                                        .overlay(
                                            Circle()
                                                .stroke(answer == colorOption.name.lowercased() ? Color.blue : Color.gray.opacity(0.3), lineWidth: answer == colorOption.name.lowercased() ? 3 : 1)
                                        )
                                    
                                    if answer == colorOption.name.lowercased() {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.white)
                                            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                                    }
                                }
                                
                                Text(colorOption.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(answer == colorOption.name.lowercased() ? .blue : .primary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Frequency Selection Answer View
struct FrequencySelectionAnswerView: View {
    let question: QuestionnaireQuestion
    @Binding var answer: String
    
    // Define frequency options
    private let frequencyOptions: [(label: String, value: String)] = [
        ("0 times", "0"),
        ("1 time", "1"),
        ("2-3 times", "2-3"),
        ("more than 3 times", "more_than_3")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How often?")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ForEach(frequencyOptions, id: \.value) { option in
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
}

// MARK: - Breathlessness Severity Answer View
struct BreathlessnessSeverityAnswerView: View {
    let question: QuestionnaireQuestion
    @Binding var answer: String
    
    // Define breathlessness severity options
    private let severityOptions: [(number: String, label: String, value: String)] = [
        ("1", "no breathless", "1"),
        ("2", "mild breathlessness", "2"),
        ("3", "moderate breathlessness", "3"),
        ("4", "severe breathlessness", "4"),
        ("5", "very breathlessness", "5")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select severity level:")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ForEach(severityOptions, id: \.value) { option in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            answer = option.value
                        }
                    }) {
                        HStack {
                            // Number circle
                            ZStack {
                                Circle()
                                    .fill(answer == option.value ? Color.blue : Color.gray.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                
                                Text(option.number)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(answer == option.value ? .white : .primary)
                            }
                            
                            // Label
                            Text(option.label)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                            
                            // Selection indicator
                            if answer == option.value {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.blue)
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
}