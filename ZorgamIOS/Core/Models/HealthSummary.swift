

// MARK: - Health Summary Models
struct HealthSummary: Codable {
    let checkInsCompleted: Int
    let totalCheckIns: Int
    let mmrcStatus: String
    let phq2Status: String
    let pointsEarned: Int
    let lastCheckInDate: String
    let weeklyProgress: WeeklyProgress
    let monthlyProgress: MonthlyProgress
    
    enum CodingKeys: String, CodingKey {
        case checkInsCompleted
        case totalCheckIns
        case mmrcStatus
        case phq2Status
        case pointsEarned
        case lastCheckInDate
        case weeklyProgress
        case monthlyProgress
    }
}

struct WeeklyProgress: Codable {
    let daily: Int
    let weekly: Int
    let monthly: Int
}

struct MonthlyProgress: Codable {
    let completed: Int
    let total: Int
    let percentage: Double
}

// MARK: - Weather Models
struct WeatherData: Codable {
    let temperature: Double
    let humidity: Double
    let condition: String
    let windSpeed: Double
    let location: String
    let timestamp: String
    let airQuality: AirQuality?
    let pollen: PollenData?
    let uvIndex: Double?
    let visibility: Double?
}

struct AirQuality: Codable {
    let aqi: Int
    let pm25: Double
    let pm10: Double
    let o3: Double
    let no2: Double
    let co: Double
    let so2: Double
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case aqi
        case pm25 = "pm2_5"
        case pm10
        case o3
        case no2
        case co
        case so2
        case status
    }
}

struct PollenData: Codable {
    let grassPollen: Int
    let treePollen: Int
    let ragweedPollen: Int
    let grassPollenRisk: String
    let treePollenRisk: String
    let ragweedPollenRisk: String
}

// MARK: - Dashboard Stats
struct DashboardStats {
    let totalCheckIns: Int
    let dailyCheckIns: Int
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
