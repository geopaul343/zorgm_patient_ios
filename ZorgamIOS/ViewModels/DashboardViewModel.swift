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
    @Published var totalPoints: Int = 0
    @Published var pointsEarned: Int = 0
    @Published var showConfetti: Bool = false
    @Published var showPointsPopup: Bool = false
    @Published var isInitialLoadComplete: Bool = false
    
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
        
        // Load points
        await loadPoints()
        
        // Load weather data
        await loadWeatherData()
        
        isLoading = false
        isInitialLoadComplete = true
    }
    
    @MainActor
    func refreshData() async {
        // Clear weather cache to force fresh data on manual refresh
        weatherService.clearCache()
        await loadData()
    }
    
    func startAutoRefresh() {
        // Stop any existing timer
        stopAutoRefresh()
        
        // Start new timer for every 30 minutes (1800 seconds) to check if cache needs refresh
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            Task { @MainActor in
                print("🔄 Auto-refresh check for weather data...")
                await self?.refreshWeatherDataIfNeeded()
            }
        }
        print("⏰ Auto-refresh timer started (every 30 minutes)")
    }
    
    @MainActor
    private func refreshWeatherDataIfNeeded() async {
        // Only refresh if we don't have cached data or it's expired
        if weatherService.getCachedWeather() == nil {
            print("🔄 No cached weather data, refreshing...")
            await loadWeatherData()
        } else {
            print("🔄 Weather data is still fresh, skipping refresh")
        }
    }
    
    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        print("⏹️ Auto-refresh timer stopped")
    }
    
    init() {
        // Listen for assessment submission notifications
        NotificationCenter.default.publisher(for: .assessmentSubmittedSuccessfully)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.triggerConfettiAndUpdatePoints()
                }
            }
            .store(in: &cancellables)
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
    
    // MARK: - Cache Management
    func getCacheStatus() -> String {
        if let cachedWeather = weatherService.getCachedWeather() {
            return "✅ Weather data cached and valid"
        } else {
            return "❌ No valid weather cache"
        }
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func loadWeatherData() async {
        print("🌤️ Loading weather data...")
        
        // First, try to get cached weather data
        if let cachedWeather = weatherService.getCachedWeather() {
            print("🌤️ Using cached weather data")
            self.weather = cachedWeather
            return
        }
        
        print("🌤️ No valid cache, fetching from API...")
        
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
        print("📊 Loading dashboard stats from submissions...")
        
        return await withCheckedContinuation { continuation in
            apiService.getSubmissions()
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("❌ Failed to load submissions: \(error)")
                            // Fallback to mock data
                            self.stats = DashboardStats(
                                totalCheckIns: 0,
                                dailyCheckIns: 0,
                                weeklyAssessments: 0,
                                monthlyAssessments: 0,
                                medicationCount: 0
                            )
                        }
                        continuation.resume()
                    },
                    receiveValue: { submissions in
                        print("✅ Submissions loaded successfully: \(submissions.count) total")
                        self.stats = self.calculateStatsFromSubmissions(submissions)
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    private func calculateStatsFromSubmissions(_ submissions: [SubmissionResponses]) -> DashboardStats {
        var dailyCount = 0
        var weeklyCount = 0
        var monthlyCount = 0
        var oneTimeCount = 0
        
        print("🔍 Processing \(submissions.count) submissions...")
        
        for submission in submissions {
            let checkinType = submission.checkinType.lowercased()
            print("📋 Processing submission ID: \(submission.id), Check-in Type: '\(checkinType)'")
            
            switch checkinType {
            case "daily":
                dailyCount += 1
                print("  ✅ Counted as daily")
            case "weekly":
                weeklyCount += 1
                print("  ✅ Counted as weekly")
            case "monthly":
                monthlyCount += 1
                print("  ✅ Counted as monthly")
            case "one_time":
                oneTimeCount += 1
                print("  ⏭️ Skipped one_time submission")
            default:
                // Count unknown types as daily for now
                dailyCount += 1
                print("  ⚠️ Unknown check-in type '\(submission.checkinType)' counted as daily")
            }
        }
        
        let totalCheckIns = dailyCount + weeklyCount + monthlyCount
        
        print("📊 Final calculated stats:")
        print("  📅 Daily: \(dailyCount)")
        print("  📊 Weekly: \(weeklyCount)")
        print("  📆 Monthly: \(monthlyCount)")
        print("  ⏭️ One-time (excluded): \(oneTimeCount)")
        print("  📈 Total (excluding one-time): \(totalCheckIns)")
        
        return DashboardStats(
            totalCheckIns: totalCheckIns,
            dailyCheckIns: dailyCount,
            weeklyAssessments: weeklyCount,
            monthlyAssessments: monthlyCount,
            medicationCount: 0 // This will be loaded separately if needed
        )
    }
    
    @MainActor
    private func loadPoints() async {
        return await withCheckedContinuation { continuation in
            apiService.getMyTotalPoints()
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("❌ Failed to load points: \(error)")
                            // Set default points if API fails
                            self.totalPoints = 1250
                        }
                        continuation.resume()
                    },
                    receiveValue: { points in
                        print("✅ Points loaded successfully: \(points)")
                        self.totalPoints = points
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    @MainActor
    func triggerConfettiAndUpdatePoints() async {
        // Only show confetti if initial load is complete
        guard isInitialLoadComplete else { return }
        
        // Store previous points to calculate earned points
        let previousPoints = totalPoints
        
        // Load updated points and dashboard stats
        print("🔄 Refreshing dashboard stats after assessment submission...")
        await loadPoints()
        await loadDashboardStats()
        print("✅ Dashboard stats refreshed successfully")
        
        // Calculate points earned (difference between new and old points)
        pointsEarned = max(0, totalPoints - previousPoints)
        
        // Show confetti animation and points popup
        showConfetti = true
        showPointsPopup = true
        
        // Hide confetti after animation duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showConfetti = false
        }
        
        // Hide points popup after a longer duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.showPointsPopup = false
        }
    }
}

