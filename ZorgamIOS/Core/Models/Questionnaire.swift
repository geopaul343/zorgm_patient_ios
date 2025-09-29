import Foundation

// MARK: - Questionnaire Models (Updated to match Kotlin API)
struct Questionnaire: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String
    let questions: [QuestionnaireQuestion]
}

struct QuestionnaireQuestion: Codable, Identifiable {
    let id: Int
    let title: String
    let subtitle: String?
    let questionType: String
    let options: [QuestionnaireOption]
    let isRequired: Bool
    let key: String
    let sequence: Int
    
    enum CodingKeys: String, CodingKey {
        case id, title, subtitle
        case questionType = "question_type"
        case options, isRequired = "is_required"
        case key, sequence
    }
}

struct QuestionnaireOption: Codable, Identifiable {
    let id: Int
    let label: String
    let value: String
}

// MARK: - Submission Models (Updated to match Kotlin API)
struct QuestionnaireSubmission: Codable {
    let questionnaireId: Int
    let answersJson: [String: String]
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case questionnaireId = "questionnaire_id"
        case answersJson = "answers_json"
        case status
    }
}

struct SubmissionResponse: Codable {
    let id: Int
    let userId: Int
    let questionnaireId: Int
    let answersJson: [String: String]
    let status: String
    let nurseComments: String?
    let reviewedByNurseId: Int?
    let reviewedAt: String?
    let submittedAt: String
    let createdAt: String
    let updatedAt: String
    let alertLevel: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case questionnaireId = "questionnaire_id"
        case answersJson = "answers_json"
        case status
        case nurseComments = "nurse_comments"
        case reviewedByNurseId = "reviewed_by_nurse_id"
        case reviewedAt = "reviewed_at"
        case submittedAt = "submitted_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case alertLevel = "alert_level"
    }
}

// MARK: - Questionnaire Question Types
enum QuestionnaireQuestionType: String, CaseIterable {
    case multipleChoice = "multiple_choice"
    case singleChoice = "single_choice"
    case text = "text"
    case number = "number"
    case scale = "scale"
    case boolean = "boolean"
    
    var displayName: String {
        switch self {
        case .multipleChoice: return "Multiple Choice"
        case .singleChoice: return "Single Choice"
        case .text: return "Text Input"
        case .number: return "Number Input"
        case .scale: return "Scale"
        case .boolean: return "Yes/No"
        }
    }
}

