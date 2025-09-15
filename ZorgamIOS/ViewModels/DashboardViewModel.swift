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
        
        // Load health summary
        await loadHealthSummary()
        
        // Load weather data
        await loadWeatherData()
        
        // Load dashboard stats
        await loadDashboardStats()
        
        isLoading = false
    }
    
    @MainActor
    func refreshData() async {
        await loadData()
    }
    
    // MARK: - Private Methods
    private func loadHealthSummary() async {
        apiService.getHealthSummary()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    if case .failure(let error) = result {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] summary in
                    self?.healthSummary = summary
                }
            )
            .store(in: &cancellables)
    }
    
    private func loadWeatherData() async {
        apiService.getWeatherData()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] weather in
                    self?.weather = weather
                }
            )
            .store(in: &cancellables)
    }
    
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
