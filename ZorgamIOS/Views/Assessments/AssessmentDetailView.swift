import SwiftUI

// MARK: - Assessment Detail View
struct AssessmentDetailView: View {
    // MARK: - Properties
    let assessmentType: AssessmentType
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @StateObject private var viewModel = AssessmentDetailViewModel()
    @State private var currentQuestionIndex = 0
    @State private var answers: [String: String] = [:]
    @State private var showingCompletion = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    ProgressView("Loading assessment...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.questions.isEmpty {
                    EmptyAssessmentView(assessmentType: assessmentType)
                } else {
                    VStack(spacing: 0) {
                        // Progress Bar
                        ProgressView(
                            value: Double(currentQuestionIndex + 1),
                            total: Double(viewModel.questions.count)
                        )
                        .progressViewStyle(LinearProgressViewStyle())
                        .padding()
                        
                        // Question Content
                        ScrollView {
                            VStack(spacing: 20) {
                                if currentQuestionIndex < viewModel.questions.count {
                                    let question = viewModel.questions[currentQuestionIndex]
                                    
                                    QuestionView(
                                        question: question,
                                        answer: answers[question.key] ?? "",
                                        onAnswerChange: { answer in
                                            answers[question.key] = answer
                                        }
                                    )
                                }
                            }
                            .padding()
                        }
                        
                        // Navigation Buttons
                        HStack(spacing: 16) {
                            if currentQuestionIndex > 0 {
                                Button("Previous") {
                                    withAnimation {
                                        currentQuestionIndex -= 1
                                    }
                                }
                                .buttonStyle(SecondaryButtonStyle())
                            }
                            
                            Spacer()
                            
                            if currentQuestionIndex < viewModel.questions.count - 1 {
                                Button("Next") {
                                    withAnimation {
                                        currentQuestionIndex += 1
                                    }
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                .disabled(!canProceed)
                            } else {
                                Button("Submit") {
                                    submitAssessment()
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                .disabled(!canProceed)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(assessmentType.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Assessment Complete", isPresented: $showingCompletion) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your assessment has been submitted successfully!")
            }
        }
        .onAppear {
            Task {
                await viewModel.loadAssessment(type: assessmentType)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var canProceed: Bool {
        guard currentQuestionIndex < viewModel.questions.count else { return false }
        let question = viewModel.questions[currentQuestionIndex]
        
        if question.isRequired {
            return !(answers[question.key]?.isEmpty ?? true)
        }
        return true
    }
    
    // MARK: - Private Methods
    private func submitAssessment() {
        Task {
            await viewModel.submitAssessment(answers: answers)
            showingCompletion = true
        }
    }
}

// MARK: - Empty Assessment View
struct EmptyAssessmentView: View {
    let assessmentType: AssessmentType
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: assessmentType.icon)
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.6))
            
            Text("No Questions Available")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("There are no questions available for this assessment at the moment.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Question View
struct QuestionView: View {
    let question: Question
    let answer: String
    let onAnswerChange: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question Title
            Text(question.title)
                .font(.headline)
                .fontWeight(.semibold)
            
            // Question Subtitle
            if let subtitle = question.subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Answer Input
            switch QuestionType(rawValue: question.questionType) {
            case .singleChoice:
                SingleChoiceView(
                    question: question,
                    answer: answer,
                    onAnswerChange: onAnswerChange
                )
                
            case .multipleChoice:
                MultipleChoiceView(
                    question: question,
                    answer: answer,
                    onAnswerChange: onAnswerChange
                )
                
            case .textInput:
                TextInputView(
                    question: question,
                    answer: answer,
                    onAnswerChange: onAnswerChange
                )
                
            case .textArea:
                TextAreaView(
                    question: question,
                    answer: answer,
                    onAnswerChange: onAnswerChange
                )
                
            case .scale:
                ScaleView(
                    question: question,
                    answer: answer,
                    onAnswerChange: onAnswerChange
                )
                
            default:
                Text("Unsupported question type")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Single Choice View
struct SingleChoiceView: View {
    let question: Question
    let answer: String
    let onAnswerChange: (String) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(question.options) { option in
                Button(action: {
                    onAnswerChange(option.value)
                }) {
                    HStack {
                        Text(option.label)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: answer == option.value ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(answer == option.value ? .blue : .gray)
                    }
                    .padding()
                    .background(answer == option.value ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Multiple Choice View
struct MultipleChoiceView: View {
    let question: Question
    let answer: String
    let onAnswerChange: (String) -> Void
    
    private var selectedAnswers: Set<String> {
        Set(answer.components(separatedBy: ",").filter { !$0.isEmpty })
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(question.options) { option in
                Button(action: {
                    var newAnswers = selectedAnswers
                    if newAnswers.contains(option.value) {
                        newAnswers.remove(option.value)
                    } else {
                        newAnswers.insert(option.value)
                    }
                    onAnswerChange(Array(newAnswers).joined(separator: ","))
                }) {
                    HStack {
                        Text(option.label)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: selectedAnswers.contains(option.value) ? "checkmark.square.fill" : "square")
                            .foregroundColor(selectedAnswers.contains(option.value) ? .blue : .gray)
                    }
                    .padding()
                    .background(selectedAnswers.contains(option.value) ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Text Input View
struct TextInputView: View {
    let question: Question
    let answer: String
    let onAnswerChange: (String) -> Void
    
    var body: some View {
        TextField(
            question.placeholder ?? "Enter your answer",
            text: Binding(
                get: { answer },
                set: { onAnswerChange($0) }
            )
        )
        .textFieldStyle(RoundedBorderTextFieldStyle())
    }
}

// MARK: - Text Area View
struct TextAreaView: View {
    let question: Question
    let answer: String
    let onAnswerChange: (String) -> Void
    
    var body: some View {
        TextField(
            question.placeholder ?? "Enter your answer",
            text: Binding(
                get: { answer },
                set: { onAnswerChange($0) }
            ),
            axis: .vertical
        )
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .lineLimit(3...6)
    }
}

// MARK: - Scale View
struct ScaleView: View {
    let question: Question
    let answer: String
    let onAnswerChange: (String) -> Void
    
    @State private var scaleValue: Double = 5
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Rate from 1 to 10")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Slider(
                value: $scaleValue,
                in: 1...10,
                step: 1
            ) {
                Text("Scale")
            } minimumValueLabel: {
                Text("1")
            } maximumValueLabel: {
                Text("10")
            } onEditingChanged: { _ in
                onAnswerChange(String(Int(scaleValue)))
            }
            
            Text("\(Int(scaleValue))")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
        }
        .onAppear {
            if let value = Double(answer) {
                scaleValue = value
            }
        }
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.blue)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Preview
#Preview {
    AssessmentDetailView(assessmentType: .daily)
}
