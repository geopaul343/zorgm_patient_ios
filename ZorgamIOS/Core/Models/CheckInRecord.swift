import Foundation

// MARK: - Check-in Record Model
struct CheckInRecord: Identifiable, Codable {
    let id: UUID
    let type: CheckInType
    let submittedAt: Date
    let status: CheckInStatus
    let responses: [String: Any]
    
    init(type: CheckInType, submittedAt: Date = Date(), status: CheckInStatus = .completed, responses: [String: Any] = [:]) {
        self.id = UUID()
        self.type = type
        self.submittedAt = submittedAt
        self.status = status
        self.responses = responses
    }
    
    // Custom coding keys for responses since Any is not Codable
    enum CodingKeys: String, CodingKey {
        case id, type, submittedAt, status
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(CheckInType.self, forKey: .type)
        submittedAt = try container.decode(Date.self, forKey: .submittedAt)
        status = try container.decode(CheckInStatus.self, forKey: .status)
        responses = [:] // Simplified for now
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(submittedAt, forKey: .submittedAt)
        try container.encode(status, forKey: .status)
    }
}

// MARK: - CheckInRecord + Equatable
extension CheckInRecord: Equatable {
    static func == (lhs: CheckInRecord, rhs: CheckInRecord) -> Bool {
        return lhs.id == rhs.id &&
               lhs.type == rhs.type &&
               lhs.submittedAt == rhs.submittedAt &&
               lhs.status == rhs.status &&
               NSDictionary(dictionary: lhs.responses).isEqual(to: rhs.responses)
    }
}

// MARK: - Check-in Type
enum CheckInType: String, CaseIterable, Codable, Equatable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case oneTime = "One_time"
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .oneTime: return "One-time"
        }
    }
    
    var icon: String {
        switch self {
        case .daily: return "calendar"
        case .weekly: return "calendar.badge.clock"
        case .monthly: return "calendar.circle"
        case .oneTime: return "star.circle"
        }
    }
}

// MARK: - Check-in Status
enum CheckInStatus: String, CaseIterable, Codable, Equatable {
    case completed = "Completed"
    case pending = "Pending"
    case inProgress = "In Progress"
    case failed = "Failed"
    
    var displayName: String {
        return rawValue
    }
    
    var color: String {
        switch self {
        case .completed: return "green"
        case .pending: return "orange"
        case .inProgress: return "blue"
        case .failed: return "red"
        }
    }
}

// MARK: - Filter Type
enum FilterType: String, CaseIterable, Equatable {
    case all = "All"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case oneTime = "One_time"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .oneTime: return "One-time"
        }
    }
}

// MARK: - Sort Option
enum SortOption: String, CaseIterable, Equatable {
    case newestFirst = "Newest first"
    case oldestFirst = "Oldest first"
    case typeAscending = "Type A-Z"
    case typeDescending = "Type Z-A"
    
    var displayName: String {
        return rawValue
    }
}
