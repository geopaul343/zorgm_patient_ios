import SwiftUI
import Combine

// MARK: - Daily Assessment View
struct DailyAssessmentView: View {
    @StateObject private var apiService = APIService()
    @State private var questionnaires: [Questionnaire] = []
    @State private var answers: [String: String] = [:]
    @State private var isLoading = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    
    var body: some View {
            VStack {
                if isLoading {
                    ProgressView("Loading daily assessment...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if questionnaires.isEmpty {
                    EmptyStateView(
                        icon: "sun.max.fill",
                        title: "No Daily Assessment",
                    message: "Unable to load daily assessment questions."
                    )
                } else {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(questionnaires) { questionnaire in
                            QuestionnaireCard(
                                questionnaire: questionnaire,
                                answers: $answers
                            )
                        }
                        
                        // Submit Button
                        Button(action: submitAnswers) {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                                Text(isSubmitting ? "Submitting..." : "Submit Assessment")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isSubmitting ? Color.gray : Color.blue)
                            .cornerRadius(12)
                        }
                        .disabled(isSubmitting || !isFormValid)
                        .opacity(isFormValid ? 1.0 : 0.6)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .padding(.top)
                }
            }
        }
            .onAppear {
            loadQuestionnaire()
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK") {
                // Reset form or navigate back
                answers.removeAll()
            }
        } message: {
            Text("Your daily assessment has been submitted successfully!")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "Failed to submit assessment. Please try again.")
        }
    }
    
           private var isFormValid: Bool {
               // Check if all required questions are answered
               for questionnaire in questionnaires {
                   for question in questionnaire.questions {
                       if question.isRequired && answers[question.key]?.isEmpty != false {
                           return false
                       }
                   }
               }
               return !questionnaires.isEmpty
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
                    print("✅ Loaded \(questionnaires.count) questionnaires")
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
}

// MARK: - Questionnaire Card
struct QuestionnaireCard: View {
    let questionnaire: Questionnaire
    @Binding var answers: [String: String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text(questionnaire.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if !questionnaire.description.isEmpty {
                    Text(questionnaire.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Questions
            LazyVStack(spacing: 16) {
                ForEach(questionnaire.questions.sorted(by: { $0.sequence < $1.sequence })) { question in
                    QuestionnaireQuestionView(
                        question: question,
                        answer: Binding(
                            get: { answers[question.key] ?? "" },
                            set: { answers[question.key] = $0 }
                        )
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
}

// MARK: - Questionnaire Question View
struct QuestionnaireQuestionView: View {
    let question: QuestionnaireQuestion
    @Binding var answer: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Question Title
            HStack {
                Text(question.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if question.isRequired {
                    Text("*")
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                }
            }
            
                   // Question Subtitle
                   if let subtitle = question.subtitle, !subtitle.isEmpty {
                       Text(subtitle)
                           .font(.subheadline)
                           .foregroundColor(.secondary)
                   }
            
            // Answer Input
            answerInputView
        }
    }
    
    @ViewBuilder
    private var answerInputView: some View {
        switch QuestionnaireQuestionType(rawValue: question.questionType) {
        case .multipleChoice, .singleChoice:
            LazyVStack(spacing: 8) {
                ForEach(question.options) { option in
                    Button(action: {
                        if QuestionnaireQuestionType(rawValue: question.questionType) == .multipleChoice {
                            // Multiple choice - toggle selection
                            toggleMultipleChoiceAnswer(option.value)
                        } else {
                            // Single choice - replace selection
                            answer = option.value
                        }
                    }) {
                        HStack {
                            Image(systemName: isOptionSelected(option.value) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isOptionSelected(option.value) ? .blue : .gray)
                            
                            Text(option.label)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding()
                        .background(isOptionSelected(option.value) ? Color.blue.opacity(0.1) : Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
               case .text:
                   TextField("Enter your answer", text: $answer)
                       .textFieldStyle(RoundedBorderTextFieldStyle())
                   
               case .number:
                   TextField("Enter number", text: $answer)
                       .textFieldStyle(RoundedBorderTextFieldStyle())
                       .keyboardType(.numberPad)
            
               case .boolean:
                   HStack {
                       Button(action: { answer = "true" }) {
                           HStack {
                               Image(systemName: answer == "true" ? "checkmark.circle.fill" : "circle")
                               Text("Yes")
                           }
                           .foregroundColor(answer == "true" ? .blue : .gray)
                       }
                       .buttonStyle(PlainButtonStyle())
                       
                       Button(action: { answer = "false" }) {
                           HStack {
                               Image(systemName: answer == "false" ? "checkmark.circle.fill" : "circle")
                               Text("No")
                           }
                           .foregroundColor(answer == "false" ? .blue : .gray)
                       }
                       .buttonStyle(PlainButtonStyle())
                       
                       Spacer()
                   }
            
               default:
                   TextField("Enter your answer", text: $answer)
                       .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
    
           private func isOptionSelected(_ value: String) -> Bool {
               if QuestionnaireQuestionType(rawValue: question.questionType) == .multipleChoice {
                   return answer.components(separatedBy: ",").contains(value)
               } else {
                   return answer == value
               }
           }
           
           private func toggleMultipleChoiceAnswer(_ value: String) {
               let currentAnswers = answer.components(separatedBy: ",").filter { !$0.isEmpty }
               
               if currentAnswers.contains(value) {
                   // Remove from selection
                   let newAnswers = currentAnswers.filter { $0 != value }
                   answer = newAnswers.joined(separator: ",")
               } else {
                   // Add to selection
                   let newAnswers = currentAnswers + [value]
                   answer = newAnswers.joined(separator: ",")
               }
           }
}

// MARK: - Empty State View
struct EmptyStateView: View {
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