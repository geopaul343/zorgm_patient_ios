import SwiftUI
import Combine

// MARK: - Weekly Assessment View
struct WeeklyAssessmentView: View {
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
                ProgressView("Loading weekly assessment...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if questionnaires.isEmpty {
                EmptyStateView(
                    icon: "chart.bar.fill",
                    title: "No Weekly Assessment",
                    message: "Unable to load weekly assessment questions."
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
                            .background(isSubmitting ? Color.gray : Color.green)
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
            Text("Your weekly assessment has been submitted successfully!")
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