import Foundation
import Combine

// MARK: - Dashboard View Model
class DashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var healthSummary: HealthSummary?
    @Published var weather: WeatherData?
    @Published var stats: DashboardStats?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let apiService = APIService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    @MainActor
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        // Load dashboard stats first (this is fast)
        await loadDashboardStats()
        
        // Try to load health summary and weather data, but don't fail if they're too large
        await loadHealthSummary()
        await loadWeatherData()
        
        isLoading = false
    }
    
    @MainActor
    func refreshData() async {
        await loadData()
    }
    
    // MARK: - Private Methods
    @MainActor
    private func loadHealthSummary() async {
        print("🔄 Loading health summary from API...")
        apiService.getHealthSummary()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    switch result {
                    case .finished:
                        print("✅ Health summary API call completed successfully")
                    case .failure(let error):
                        print("❌ Health summary API call failed: \(error.localizedDescription)")
                        // Always fall back to mock data for now
                        self?.loadMockHealthSummary()
                    }
                },
                receiveValue: { [weak self] summary in
                    print("📊 Health summary received: \(summary)")
                    self?.healthSummary = summary
                }
            )
            .store(in: &cancellables)
    }

    @MainActor
    private func loadMockHealthSummary() {
        healthSummary = HealthSummary(
            checkInsCompleted: 12,
            totalCheckIns: 22,
            mmrcStatus: "Good",
            phq2Status: "Normal",
            pointsEarned: 150,
            lastCheckInDate: "2025-09-16T10:30:00Z",
            weeklyProgress: WeeklyProgress(
                daily: 12,
                weekly: 45,
                monthly: 22
            ),
            monthlyProgress: MonthlyProgress(
                completed: 22,
                total: 30,
                percentage: 73.3
            )
        )
    }
    
    @MainActor
    private func loadWeatherData() async {
        // TODO: Replace with real API call when weather endpoint is available
        // Example: apiService.getWeatherData()
        // For now, always use mock data to ensure weather card shows
        loadMockWeatherData()
    }
    
    // MARK: - Future API Integration
    // Uncomment this method when weather API is ready
    /*
    @MainActor
    private func loadWeatherDataFromAPI() async {
        apiService.getWeatherData()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    if case .failure(let error) = result {
                        print("❌ Weather API Error: \(error.localizedDescription)")
                        // Fallback to mock data
                        self?.loadMockWeatherData()
                    }
                },
                receiveValue: { [weak self] weather in
                    print("✅ Weather API Success: \(weather.location)")
                    self?.weather = weather
                }
            )
            .store(in: &cancellables)
    }
    */
    
    @MainActor
    private func loadMockWeatherData() {
        // Provide mock weather data
        weather = WeatherData(
            temperature: 72,
            humidity: 65,
            condition: "Sunny",
            windSpeed: 8.5,
            location: "London, UK",
            timestamp: ISO8601DateFormatter().string(from: Date()),
            airQuality: AirQuality(
                aqi: 45,
                pm25: 12.5,
                pm10: 18.2,
                o3: 0.08,
                no2: 0.02,
                co: 0.5,
                so2: 0.01,
                status: "Good"
            ),
            uvIndex: 6.5,
            visibility: 10.0
        )
    }
    
    @MainActor
    private func loadDashboardStats() async {
        // For now, create mock stats
        // In a real app, this would come from the API
        stats = DashboardStats(
            totalCheckIns: 15,
            weeklyAssessments: 3,
            monthlyAssessments: 1,
            medicationCount: 5
        )
    }
}
