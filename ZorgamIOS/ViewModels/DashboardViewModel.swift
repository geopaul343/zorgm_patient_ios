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
        apiService.getHealthSummary()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    if case .failure(let error) = result {
                        // If the response is too large, use mock data instead
                        if error.localizedDescription.contains("resource exceeds maximum size") {
                            self?.loadMockHealthSummary()
                        } else {
                            self?.errorMessage = error.localizedDescription
                        }
                    }
                },
                receiveValue: { [weak self] summary in
                    self?.healthSummary = summary
                }
            )
            .store(in: &cancellables)
    }

    @MainActor
    private func loadMockHealthSummary() {
        healthSummary = HealthSummary(
            patientId: "12345",
            totalAssessments: 10,
            completedAssessments: 7,
            pendingAssessments: 3,
            lastAssessmentDate: "2025-09-15",
            healthScore: 85.5,
            trends: HealthTrends(
                moodTrend: "Improving",
                energyTrend: "Stable",
                symptomTrend: "Decreasing",
                medicationAdherence: 0.9   // Double value (e.g., 90%)
            ),
            recommendations: [
                "Exercise regularly",
                "Maintain a balanced diet",
                "Monitor mood weekly"
            ]
        )
    }
    
    @MainActor
    private func loadWeatherData() async {
        apiService.getWeatherData()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    if case .failure(let error) = result {
                        // If the response is too large, use mock data instead
                        if error.localizedDescription.contains("resource exceeds maximum size") {
                            self?.loadMockWeatherData()
                        }
                    }
                },
                receiveValue: { [weak self] weather in
                    self?.weather = weather
                }
            )
            .store(in: &cancellables)
    }
    
    @MainActor
    private func loadMockWeatherData() {
        // Provide mock weather data
        weather = WeatherData(
            temperature: 72,
            humidity: 65,
            condition: "Sunny",
            windSpeed: 8.5,
            location: "London, UK",
            timestamp: ISO8601DateFormatter().string(from: Date())
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
