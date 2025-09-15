

// MARK: - Health Summary Models
struct HealthSummary: Codable {
    let patientId: String
    let totalAssessments: Int
    let completedAssessments: Int
    let pendingAssessments: Int
    let lastAssessmentDate: String?
    let healthScore: Double
    let trends: HealthTrends
    let recommendations: [String]
    
    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case totalAssessments = "total_assessments"
        case completedAssessments = "completed_assessments"
        case pendingAssessments = "pending_assessments"
        case lastAssessmentDate = "last_assessment_date"
        case healthScore = "health_score"
        case trends
        case recommendations
    }
}

struct HealthTrends: Codable {
    let moodTrend: String
    let energyTrend: String
    let symptomTrend: String
    let medicationAdherence: Double
    
    enum CodingKeys: String, CodingKey {
        case moodTrend = "mood_trend"
        case energyTrend = "energy_trend"
        case symptomTrend = "symptom_trend"
        case medicationAdherence = "medication_adherence"
    }
}

// MARK: - Weather Models
struct WeatherData: Codable {
    let temperature: Double
    let humidity: Double
    let condition: String
    let windSpeed: Double
    let location: String
    let timestamp: String
}

// MARK: - Dashboard Stats
struct DashboardStats {
    let totalCheckIns: Int
    let weeklyAssessments: Int
    let monthlyAssessments: Int
    let medicationCount: Int
}

// MARK: - Health Summary UI State
struct HealthSummaryUIState {
    var summary: HealthSummary?
    var weather: WeatherData?
    var stats: DashboardStats?
    var isLoading: Bool = false
    var error: String? = nil
}

// MARK: - Health Summary Result
enum HealthSummaryResult {
    case success(HealthSummary)
    case failure(String)
    case loading
}
