import SwiftUI

// MARK: - History Detail View
struct HistoryDetailView: View {
    // MARK: - Properties
    let submission: SubmissionResponses
    @StateObject private var viewModel = HistoryDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    // Loading State
                    VStack(spacing: 20) {
                        Spacer()
                        
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        
                        VStack(spacing: 8) {
                            Text("Loading Details...")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("Fetching questionnaire and answers")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                } else if let errorMessage = viewModel.errorMessage {
                    // Error State
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 64))
                            .foregroundColor(.red)
                        
                        VStack(spacing: 8) {
                            Text("Error Loading Data")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        Button(action: {
                            Task {
                                await viewModel.loadDetailData(submission: submission)
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Retry")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red)
                            )
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                } else {
                    // Content State
                    ScrollView {
                        VStack(spacing: 16) {
                            // Health Assessment Card
                            HealthAssessmentCard(
                                checkinType: CheckInType.fromString(submission.checkinType),
                                submittedAt: submission.submittedAt,
                                submissionId: submission.id,
                                status: CheckInStatus.fromString(submission.status)
                            )
                            
                            // Nurse Feedback Card
                            if let nurseComments = submission.nurseComments, !nurseComments.isEmpty {
                                NurseFeedbackCard(
                                    comments: nurseComments,
                                    reviewedBy: submission.reviewedByNurse
                                )
                            }
                            
                            // Answers Section
                            if !viewModel.answers.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Answers")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .padding(.horizontal)
                                    
                                    LazyVStack(spacing: 12) {
                                        ForEach(viewModel.answers) { answer in
                                            AnswerCard(answer: answer)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            } else if !viewModel.isLoading {
                                // No answers found
                                VStack(spacing: 12) {
                                    Image(systemName: "questionmark.circle")
                                        .font(.system(size: 48))
                                        .foregroundColor(.secondary)
                                    
                                    Text("No Answers Found")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    
                                    Text("No answers were found for this submission")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Submission Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await viewModel.refreshData()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadDetailData(submission: submission)
            }
        }
    }
}

// MARK: - Health Assessment Card
struct HealthAssessmentCard: View {
    let checkinType: CheckInType
    let submittedAt: String
    let submissionId: Int
    let status: CheckInStatus
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // Icon
                Image(systemName: "cross.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.green)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Health Assessment")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(checkinType.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status Badge
                HStack(spacing: 4) {
                    Image(systemName: statusIcon)
                        .font(.caption)
                        .foregroundColor(.white)
                    Text(status.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(statusColor)
                .clipShape(Capsule())
            }
            
            HStack {
                Text("Submitted on \(formatDate(submittedAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Submission ID #\(submissionId)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, yyyy HH:mm"
            return displayFormatter.string(from: date)
        }
        return dateString
    }
    
    private var statusIcon: String {
        switch status {
        case .completed:
            return "checkmark"
        case .pending:
            return "clock"
        case .inProgress:
            return "arrow.clockwise"
        case .failed:
            return "xmark"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .completed:
            return .green
        case .pending:
            return .orange
        case .inProgress:
            return .blue
        case .failed:
            return .red
        }
    }
}

// MARK: - Nurse Feedback Card
struct NurseFeedbackCard: View {
    let comments: String
    let reviewedBy: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 30, height: 30)
                
                Text("Nurse Feedback")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Text("Professional review and recommendations.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Comments")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(comments)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            if let reviewer = reviewedBy {
                HStack {
                    Image(systemName: "person.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Reviewed by \(reviewer)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
}

// MARK: - Answer Card
struct AnswerCard: View {
    let answer: QuestionAnswer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(answer.questionTitle)
                .font(.headline)
                .fontWeight(.medium)
            
            if let subtitle = answer.questionSubtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Answer:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(answer.answer)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Preview
#Preview {
    let mockSubmission = SubmissionResponses(
        id: 43,
        userId: 1,
        questionnaireId: 1,
        checkinType: "WEEKLY",
        answersJson: ["breathing_exercises": "Yes", "walking_days": "5"],
        status: "completed",
        nurseComments: "Needs improvement",
        submittedAt: "2025-09-24T16:44:00Z",
        createdAt: "2025-09-24T16:44:00Z",
        updatedAt: "2025-09-24T16:44:00Z",
        alertLevel: "low",
        diseaseId: 1,
        diseaseName: "COPD",
        reviewedByNurseId: 1,
        reviewedAt: "2025-09-24T17:00:00Z",
        user: "John Doe",
        reviewedByNurse: "healthcare professional"
    )
    
    HistoryDetailView(submission: mockSubmission)
}
