import Foundation

// MARK: - Health Assessment Models
struct HealthAssessmentResponse: Codable {
    let id: Int
    let regionCode: String
    let diseaseId: Int
    let checkinType: String
    let version: String
    let title: String
    let description: String
    let createdAt: String
    let updatedAt: String
    let questions: [Question]
    
    enum CodingKeys: String, CodingKey {
        case id
        case regionCode = "region_code"
        case diseaseId = "disease_id"
        case checkinType = "checkin_type"
        case version
        case title
        case description
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case questions
    }
}

struct Question: Codable, Identifiable {
    let id: Int
    let sequence: Int
    let key: String
    let questionType: String
    let title: String
    let subtitle: String?
    let placeholder: String?
    let isRequired: Bool
    let hasTextInput: Bool
    let textInputPlaceholder: String?
    let createdAt: String
    let updatedAt: String
    let options: [QuestionOption]
    let visibilityRules: [String] // Simplified for now
    
    enum CodingKeys: String, CodingKey {
        case id
        case sequence
        case key
        case questionType = "question_type"
        case title
        case subtitle
        case placeholder
        case isRequired = "is_required"
        case hasTextInput = "has_text_input"
        case textInputPlaceholder = "text_input_placeholder"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case options
        case visibilityRules = "visibility_rules"
    }
}

struct QuestionOption: Codable, Identifiable {
    let id: Int
    let sequence: Int
    let label: String
    let value: String
    let hasTextInput: Bool
    let textInputPlaceholder: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case sequence
        case label
        case value
        case hasTextInput = "has_text_input"
        case textInputPlaceholder = "text_input_placeholder"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Assessment Types
enum AssessmentType: String, CaseIterable {
    case daily = "DAILY"
    case weekly = "WEEKLY"
    case monthly = "MONTHLY"
    
    var displayName: String {
        switch self {
        case .daily: return "Daily Check-in"
        case .weekly: return "Weekly Assessment"
        case .monthly: return "Monthly Assessment"
        }
    }
    
    var icon: String {
        switch self {
        case .daily: return "checkmark.circle.fill"
        case .weekly: return "calendar"
        case .monthly: return "star.fill"
        }
    }
}

// MARK: - Question Types
enum QuestionType: String, CaseIterable {
    case acknowledgement = "ACKNOWLEDGEMENT"
    case singleChoice = "SINGLE_CHOICE"
    case multipleChoice = "MULTIPLE_CHOICE"
    case textInput = "TEXT_INPUT"
    case textArea = "TEXT_AREA"
    case scale = "SCALE"
    case unknown = "UNKNOWN"
}

// MARK: - Assessment UI State
struct AssessmentUIState {
    var questions: [Question] = []
    var currentQuestionIndex: Int = 0
    var answers: [String: String] = [:]
    var isLoading: Bool = false
    var isSubmitting: Bool = false
    var error: String? = nil
    var submissionSuccess: Bool = false
    var canProceed: Bool = false
}

// MARK: - Assessment Result
enum AssessmentResult: Codable {
    case success
    case failure(String)
    case loading
    
    enum CodingKeys: String, CodingKey {
        case success, failure, loading
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let success = try? container.decode(Bool.self) {
            self = success ? .success : .failure("Unknown error")
        } else if let message = try? container.decode(String.self) {
            self = .failure(message)
        } else {
            self = .loading
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .success:
            try container.encode(true)
        case .failure(let message):
            try container.encode(message)
        case .loading:
            try container.encode("loading")
        }
    }
}
