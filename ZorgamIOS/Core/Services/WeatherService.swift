import Foundation
import CoreLocation
import Combine

// MARK: - Weather Cache
struct WeatherCache {
    let data: WeatherData
    let timestamp: Date
    let location: CLLocation
    
    var isExpired: Bool {
        let oneHour: TimeInterval = 3600 // 1 hour in seconds
        return Date().timeIntervalSince(timestamp) > oneHour
    }
}

// MARK: - Weather Service
class WeatherService: NSObject, ObservableObject {
    private let apiKey = "AIzaSyCPpaDH4PV-qo6nQ3vLMllan04YOxmBjfE"
    private let baseURL = "https://airquality.googleapis.com/v1"
    private let locationManager = CLLocationManager()
    
    @Published var currentLocation: CLLocation?
    @Published var locationPermissionStatus: CLAuthorizationStatus = .notDetermined
    
    private var cancellables = Set<AnyCancellable>()
    private var weatherCache: WeatherCache?
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Location Management
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startLocationUpdates() {
        guard locationPermissionStatus == .authorizedWhenInUse || locationPermissionStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - Test API Method
    func testAPIWithCoordinates(latitude: Double, longitude: Double) -> AnyPublisher<WeatherData, Error> {
        print("🧪 Testing API with coordinates: \(latitude), \(longitude)")
        
        return getAirQualityData(latitude: latitude, longitude: longitude)
            .map { airQualityData in
                // Create a mock location for testing
                let testLocation = CLLocation(latitude: latitude, longitude: longitude)
                return self.createWeatherData(from: airQualityData, location: testLocation)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Weather API Methods
    func getCurrentWeather() -> AnyPublisher<WeatherData, Error> {
        guard let location = currentLocation else {
            return Fail(error: WeatherError.noLocation)
                .eraseToAnyPublisher()
        }
        
        // Check if we have valid cached data for this location
        if let cache = weatherCache,
           !cache.isExpired,
           isLocationSimilar(cache.location, location) {
            print("🌤️ Using cached weather data (age: \(Int(Date().timeIntervalSince(cache.timestamp))) seconds)")
            return Just(cache.data)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        print("🌤️ Cache miss or expired, fetching fresh weather data...")
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        
        return getAirQualityData(latitude: lat, longitude: lon)
            .map { airQualityData in
                let weatherData = self.createWeatherData(from: airQualityData, location: location)
                // Cache the new data
                self.weatherCache = WeatherCache(data: weatherData, timestamp: Date(), location: location)
                print("🌤️ Weather data cached successfully")
                return weatherData
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Cache Management
    private func isLocationSimilar(_ location1: CLLocation, _ location2: CLLocation) -> Bool {
        // Consider locations similar if they're within 1km of each other
        let distance = location1.distance(from: location2)
        return distance < 1000 // 1km threshold
    }
    
    func clearCache() {
        weatherCache = nil
        print("🗑️ Weather cache cleared")
    }
    
    func getCachedWeather() -> WeatherData? {
        guard let cache = weatherCache, !cache.isExpired else {
            return nil
        }
        return cache.data
    }
    
    private func getAirQualityData(latitude: Double, longitude: Double) -> AnyPublisher<AirQualityAPIResponse, Error> {
        let urlString = "\(baseURL)/currentConditions:lookup?key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            return Fail(error: WeatherError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        let requestBody: [String: Any] = [
            "location": [
                "latitude": latitude,
                "longitude": longitude
            ],
            "extraComputations": [
                "LOCAL_AQI",
                "HEALTH_RECOMMENDATIONS",
                "POLLUTANT_ADDITIONAL_INFO",
                "DOMINANT_POLLUTANT_CONCENTRATION",
                "POLLUTANT_CONCENTRATION"
            ],
            "languageCode": "en"
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
        
        print("🌤️ Making API request to: \(urlString)")
        print("📍 Location: \(latitude), \(longitude)")
        print("📋 Request body: \(requestBody)")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw WeatherError.networkError("Invalid response")
                }
                
                print("📊 API Status Code: \(httpResponse.statusCode)")
                
                if !(200...299).contains(httpResponse.statusCode) {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    print("❌ API Error Response: \(errorMessage)")
                    throw WeatherError.networkError("HTTP \(httpResponse.statusCode): \(errorMessage)")
                }
                
                // Log successful response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("✅ API Response received successfully")
                    print("📦 Response data: \(responseString)") // Full response
                }
                
                return data
            }
            .decode(type: AirQualityAPIResponse.self, decoder: JSONDecoder())
            .mapError { error in
                print("❌ JSON Decoding Error: \(error)")
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("❌ Missing key: \(key) at path: \(context.codingPath)")
                    case .typeMismatch(let type, let context):
                        print("❌ Type mismatch for type: \(type) at path: \(context.codingPath)")
                    case .valueNotFound(let type, let context):
                        print("❌ Value not found for type: \(type) at path: \(context.codingPath)")
                    case .dataCorrupted(let context):
                        print("❌ Data corrupted at path: \(context.codingPath)")
                    @unknown default:
                        print("❌ Unknown decoding error")
                    }
                }
                return error
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Location Helper Methods
    private func getLocationName(from location: CLLocation) -> String {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        
        // Simple location mapping based on coordinates
        // You can add more locations as needed
        if lat >= 37.0 && lat <= 38.0 && lon >= -123.0 && lon <= -122.0 {
            return "San Francisco, CA"
        } else if lat >= 9.0 && lat <= 10.0 && lon >= 76.0 && lon <= 77.0 {
            return "Kochi, India"
        } else if lat >= 12.0 && lat <= 13.0 && lon >= 77.0 && lon <= 78.0 {
            return "Bangalore, India"
        } else if lat >= 19.0 && lat <= 20.0 && lon >= 72.0 && lon <= 73.0 {
            return "Mumbai, India"
        } else if lat >= 28.0 && lat <= 29.0 && lon >= 77.0 && lon <= 78.0 {
            return "New Delhi, India"
        } else {
            // Fallback to formatted coordinates
            return "\(String(format: "%.4f", lat)), \(String(format: "%.4f", lon))"
        }
    }
    
    private func createWeatherData(from apiResponse: AirQualityAPIResponse, location: CLLocation) -> WeatherData {
        // Get location name from coordinates
        let locationName = getLocationName(from: location)
        
        // Extract air quality data
        let aqiIndex = apiResponse.indexes.first
        let aqi = aqiIndex?.aqi ?? 0
        let status = aqiIndex?.category ?? "Unknown"
        
        // Extract pollutant data
        let pollutants = apiResponse.pollutants ?? []
        let pm25 = pollutants.first { $0.code == "pm25" }?.concentration?.value ?? 0.0
        let pm10 = pollutants.first { $0.code == "pm10" }?.concentration?.value ?? 0.0
        let o3 = pollutants.first { $0.code == "o3" }?.concentration?.value ?? 0.0
        let no2 = pollutants.first { $0.code == "no2" }?.concentration?.value ?? 0.0
        let co = pollutants.first { $0.code == "co" }?.concentration?.value ?? 0.0
        let so2 = pollutants.first { $0.code == "so2" }?.concentration?.value ?? 0.0
        
        // Note: Pollen data is not available from Google Air Quality API
        // Using mock data for demonstration purposes
        let grassPollen = 0.0
        let treePollen = 0.0
        let ragweedPollen = 0.0
        
        let grassPollenRisk = "Not Available"
        let treePollenRisk = "Not Available"
        let ragweedPollenRisk = "Not Available"
        
        print("🌤️ Parsed data - AQI: \(aqi), PM2.5: \(pm25), Status: \(status)")
        
        return WeatherData(
            temperature: 0, // Not used in UI
            humidity: 0,    // Not used in UI
            condition: "",  // Not used in UI
            windSpeed: 0,   // Not used in UI
            location: locationName,
            timestamp: apiResponse.dateTime,
            airQuality: AirQuality(
                aqi: aqi,
                pm25: pm25,
                pm10: pm10,
                o3: o3,
                no2: no2,
                co: co,
                so2: so2,
                status: status
            ),
            pollen: PollenData(
                grassPollen: Int(grassPollen),
                treePollen: Int(treePollen),
                ragweedPollen: Int(ragweedPollen),
                grassPollenRisk: grassPollenRisk,
                treePollenRisk: treePollenRisk,
                ragweedPollenRisk: ragweedPollenRisk
            ),
            uvIndex: nil,    // Not used in UI
            visibility: nil  // Not used in UI
        )
    }
}

// MARK: - CLLocationManagerDelegate
extension WeatherService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationPermissionStatus = status
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            print("Location access denied")
        case .notDetermined:
            requestLocationPermission()
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}

// MARK: - Weather Error
enum WeatherError: Error, LocalizedError {
    case noLocation
    case invalidURL
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .noLocation:
            return "Location not available"
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

// MARK: - API Request Models
struct AirQualityRequest: Codable {
    let location: Location
    let extraComputations: [String]
    let languageCode: String
}

struct Location: Codable {
    let latitude: Double
    let longitude: Double
}
    
    // MARK: - API Response Models
    struct AirQualityAPIResponse: Codable {
        let dateTime: String
        let regionCode: String
        let indexes: [AirQualityIndex]
        let pollutants: [Pollutant]?
    }

    struct AirQualityIndex: Codable {
        let code: String
        let displayName: String
        let aqi: Int
        let aqiDisplay: String
        let category: String
        let color: ColorInfo?
        let dominantPollutant: String?
    }

    struct Pollutant: Codable {
        let code: String
        let displayName: String
        let concentration: Concentration?
        let category: String?
    }

    struct Concentration: Codable {
        let value: Double
        let units: String
        let category: String?
    }

    struct ColorInfo: Codable {
        let red: Double?
        let green: Double?
        let blue: Double?
    }
