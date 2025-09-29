import Foundation

// MARK: - History Detail Model
struct HistoryDetail: Identifiable, Codable {
    let id: Int
    let submissionId: Int
    let checkinType: CheckInType
    let submittedAt: Date
    let status: CheckInStatus
    let nurseComments: String?
    let reviewedBy: String?
    let reviewedAt: Date?
    let answers: [QuestionAnswer]
    
    init(from submission: SubmissionResponses, questions: [QuestionnaireQuestion]) {
        self.id = submission.id
        self.submissionId = submission.id
        self.checkinType = CheckInType.fromString(submission.checkinType)
        self.status = CheckInStatus.fromString(submission.status)
        
        // Parse submitted date
        let dateFormatter = ISO8601DateFormatter()
        self.submittedAt = dateFormatter.date(from: submission.submittedAt) ?? Date()
        
        // Parse reviewed date if available
        if let reviewedAtString = submission.reviewedAt {
            self.reviewedAt = dateFormatter.date(from: reviewedAtString)
        } else {
            self.reviewedAt = nil
        }
        
        self.nurseComments = submission.nurseComments
        self.reviewedBy = submission.reviewedByNurse
        
        // Map answers to questions by matching question ID with answer key
        self.answers = questions.compactMap { question in
            // Try to find answer by question ID as string key
            let questionIdString = String(question.id)
            if let answerValue = submission.answersJson[questionIdString] {
                return QuestionAnswer(
                    questionId: question.id,
                    questionTitle: question.title,
                    questionSubtitle: question.subtitle,
                    answer: String(describing: answerValue),
                    questionType: question.questionType
                )
            }
            // Fallback: try to find by question key if ID doesn't work
            else if let answerValue = submission.answersJson[question.key] {
                return QuestionAnswer(
                    questionId: question.id,
                    questionTitle: question.title,
                    questionSubtitle: question.subtitle,
                    answer: String(describing: answerValue),
                    questionType: question.questionType
                )
            }
            return nil
        }.sorted { $0.questionId < $1.questionId }
    }
}

// MARK: - Question Answer Model
struct QuestionAnswer: Identifiable, Codable {
    let id = UUID()
    let questionId: Int
    let questionTitle: String
    let questionSubtitle: String?
    let answer: String
    let questionType: String
    
    enum CodingKeys: String, CodingKey {
        case questionId, questionTitle, questionSubtitle, answer, questionType
    }
}

// MARK: - CheckInType Extension
extension CheckInType {
    static func fromString(_ string: String) -> CheckInType {
        switch string.uppercased() {
        case "DAILY":
            return .daily
        case "WEEKLY":
            return .weekly
        case "MONTHLY":
            return .monthly
        case "ONE_TIME":
            return .oneTime
        default:
            return .oneTime
        }
    }
}

// MARK: - CheckInStatus Extension
extension CheckInStatus {
    static func fromString(_ string: String) -> CheckInStatus {
        switch string.lowercased() {
        case "completed", "submitted":
            return .completed
        case "pending", "pending_review":
            return .pending
        case "in_progress", "in progress":
            return .inProgress
        case "failed", "error":
            return .failed
        default:
            return .completed
        }
    }
}
