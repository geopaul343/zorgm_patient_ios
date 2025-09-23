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
    private let weatherService = WeatherService()
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    
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
    
    func startAutoRefresh() {
        // Stop any existing timer
        stopAutoRefresh()
        
        // Start new timer for every 5 minutes (300 seconds)
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                print("🔄 Auto-refreshing weather data...")
                await self?.loadWeatherData()
            }
        }
        print("⏰ Auto-refresh timer started (every 5 minutes)")
    }
    
    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        print("⏹️ Auto-refresh timer stopped")
    }
    
    deinit {
        stopAutoRefresh()
    }
    
    // MARK: - Test API Method
    @MainActor
    func testAPI() async {
        print("🧪 Manual API test triggered")
        await loadWeatherData()
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
        print("🌤️ Loading weather data from API...")
        
        // Request location permission
        weatherService.requestLocationPermission()
        
        // Start location updates
        weatherService.startLocationUpdates()
        
        // Wait a moment for location to be available
        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        
        weatherService.getCurrentWeather()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    switch result {
                    case .finished:
                        print("✅ Weather API call completed successfully")
                    case .failure(let error):
                        print("❌ Weather API call failed: \(error.localizedDescription)")
                        print("📍 Location permission status: \(self?.weatherService.locationPermissionStatus.rawValue ?? -1)")
                        print("📍 Current location: \(self?.weatherService.currentLocation?.coordinate.latitude ?? 0), \(self?.weatherService.currentLocation?.coordinate.longitude ?? 0)")
                        // Fallback to test API with fixed location if real location fails
                        print("🔄 Falling back to test API with fixed location...")
                        self?.testAPIWithFixedLocation()
                    }
                },
                receiveValue: { [weak self] weather in
                    print("🌤️ Weather data received: \(weather.location)")
                    self?.weather = weather
                }
            )
            .store(in: &cancellables)
    }
    
    @MainActor
    private func testAPIWithFixedLocation() {
        // Test with San Francisco coordinates
        let testLatitude = 37.7749
        let testLongitude = -122.4194
        
        print("🧪 Testing API with San Francisco coordinates: \(testLatitude), \(testLongitude)")
        
        weatherService.testAPIWithCoordinates(latitude: testLatitude, longitude: testLongitude)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { result in
                    switch result {
                    case .finished:
                        print("✅ Test API call completed successfully")
                    case .failure(let error):
                        print("❌ Test API call failed: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] weather in
                    print("🎉 Test API response received: \(weather.location)")
                    // Use test data if real location fails
                    self?.weather = weather
                }
            )
            .store(in: &cancellables)
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
        // Provide mock air quality and pollen data only
        weather = WeatherData(
            temperature: 0, // Not used in UI
            humidity: 0,    // Not used in UI
            condition: "",  // Not used in UI
            windSpeed: 0,   // Not used in UI
            location: "Your Location",
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
            pollen: PollenData(
                grassPollen: 0,
                treePollen: 0,
                ragweedPollen: 0,
                grassPollenRisk: "Not Available",
                treePollenRisk: "Not Available",
                ragweedPollenRisk: "Not Available"
            ),
            uvIndex: nil,    // Not used in UI
            visibility: nil  // Not used in UI
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
