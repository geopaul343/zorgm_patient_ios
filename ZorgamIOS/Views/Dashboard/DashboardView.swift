import SwiftUI

// MARK: - Dashboard View
struct DashboardView: View {
    // MARK: - Environment Objects
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var navigationManager: NavigationManager
    
    // MARK: - State
    @StateObject private var viewModel = DashboardViewModel()
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Welcome back!")
                                    .font(.title2)
                                    .fontWeight(.medium)
                                
                                Text(sessionManager.currentUser?.fullName ?? "User")
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                            
                            Spacer()
                            
                            // Profile Image Placeholder
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.blue)
                                )
                        }
                        
                        
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Health Summary Card
                    if let summary = viewModel.healthSummary {
                        HealthSummaryCard(summary: summary, isLoading: viewModel.isLoading)
                    } else if viewModel.isLoading {
                        // Show loading state
                        VStack(spacing: 24) {
                            Text("Health Summary")
                                .font(.title2)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                            
                            ProgressView("Loading health data...")
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.2)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        .padding(.horizontal)
                    } else {
                        // Show error state or empty state
                        VStack(spacing: 16) {
                            Text("Health Summary")
                                .font(.title2)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                            
                            Text("Unable to load health data")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        .padding(.horizontal)
                    }
                    
                    // Weather & Air Quality Card
                    if let weather = viewModel.weather {
                        WeatherAirQualityCard(weather: weather, isLoading: viewModel.isLoading)
                    } else {
                        // Show dummy data for weather
                        WeatherAirQualityCard(weather: WeatherData(
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
                        ), isLoading: false)
                    }
                    
                    // Quick Actions
                    QuickActionsView(
                        onDailyCheckIn: {
                            navigationManager.navigateToAssessment(.daily)
                        },
                        onMedications: {
                            navigationManager.navigateToMedications()
                        },
                        onWeeklyAssessment: {
                            navigationManager.navigateToAssessment(.weekly)
                        },
                        onMonthlyAssessment: {
                            navigationManager.navigateToAssessment(.monthly)
                        }
                    )
                    
                    // Points Card - Last element in dashboard
                    PointsCard(points: 1250)
                    
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refreshData()
            }
        }
        .onAppear {
            Task {
                await viewModel.loadData()
            }
        }
    }
}

// MARK: - Health Summary Card
struct HealthSummaryCard: View {
    let summary: HealthSummary
    let isLoading: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            
            // Heading
            Text("Health Summary")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
             // Row with 3 items (spaceBetween style)
             HStack {
                 SummaryItem(icon: "heart.fill", number: summary.weeklyProgress.daily, label: "Daily", color: .red)
                 Spacer()
                 SummaryItem(icon: "chart.bar.fill", number: summary.weeklyProgress.weekly, label: "Weekly", color: .blue)
                 Spacer()
                 SummaryItem(icon: "calendar", number: summary.weeklyProgress.monthly, label: "Monthly", color: .green)
             }
             .padding(.horizontal)
             
             // Total Submission in one row
             HStack(spacing: 8) {
                 Text("Total Submission")
                     .font(.headline)
                 Text("\(summary.totalCheckIns)")
                     .font(.headline)
                     .fontWeight(.bold)
             }
            .frame(maxWidth: .infinity, alignment: .center)
            
        }
        .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    .padding(.horizontal)
                    .blur(radius: isLoading ? 3 : 0) // blur content while loading
                    
                    // Loader overlay
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5) // make it a bit larger
                    }
    }
}

// MARK: - Summary Item
struct SummaryItem: View {
    let icon: String
    let number: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15)) // light background color
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
            }
            
            Text("\(number)")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}


// MARK: - Quick Actions View
struct QuickActionsView: View {
    let onDailyCheckIn: () -> Void
    let onMedications: () -> Void
    let onWeeklyAssessment: () -> Void
    let onMonthlyAssessment: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ActionButton(
                    icon: "checkmark.circle.fill",
                    title: "Daily Check-in",
                    color: .orange,
                    action: onDailyCheckIn
                )
                
                ActionButton(
                    icon: "pills.fill",
                    title: "Medications",
                    color: .blue,
                    action: onMedications
                )
                
                ActionButton(
                    icon: "calendar",
                    title: "Weekly Assessment",
                    color: .green,
                    action: onWeeklyAssessment
                )
                
                ActionButton(
                    icon: "star.fill",
                    title: "Monthly Assessment",
                    color: .purple,
                    action: onMonthlyAssessment
                )
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(color)
                    .clipShape(Circle())
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Weather & Air Quality Card
struct WeatherAirQualityCard: View {
    let weather: WeatherData
    let isLoading: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Weather & Air Quality")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text(weather.location)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // Main Weather Info
            HStack(spacing: 20) {
                // Temperature and condition
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: weatherIcon(for: weather.condition))
                            .font(.system(size: 32))
                            .foregroundColor(weatherColor(for: weather.condition))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(Int(weather.temperature))°C")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text(weather.condition)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Additional weather details
                VStack(alignment: .trailing, spacing: 8) {
                    WeatherDetailItem(icon: "humidity.fill", value: "\(Int(weather.humidity))%", label: "Humidity", color: .blue)
                    WeatherDetailItem(icon: "wind", value: "\(Int(weather.windSpeed)) km/h", label: "Wind", color: .green)
                    if let uvIndex = weather.uvIndex {
                        WeatherDetailItem(icon: "sun.max.fill", value: "\(Int(uvIndex))", label: "UV Index", color: .orange)
                    }
                }
            }
            .padding(.horizontal)
            
            // Air Quality Section
            if let airQuality = weather.airQuality {
                VStack(spacing: 12) {
                    HStack {
                        Text("Air Quality")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        AirQualityBadge(aqi: airQuality.aqi, status: airQuality.status)
                    }
                    
                    // Air Quality Details
                    HStack(spacing: 16) {
                        AirQualityItem(label: "PM2.5", value: "\(Int(airQuality.pm25))", color: airQualityColor(for: airQuality.pm25))
                        AirQualityItem(label: "PM10", value: "\(Int(airQuality.pm10))", color: airQualityColor(for: airQuality.pm10))
                        AirQualityItem(label: "O₃", value: "\(Int(airQuality.o3 * 100))", color: airQualityColor(for: airQuality.o3 * 100))
                        AirQualityItem(label: "NO₂", value: "\(Int(airQuality.no2 * 100))", color: airQualityColor(for: airQuality.no2 * 100))
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
        .blur(radius: isLoading ? 3 : 0)
        
        // Loader overlay
        if isLoading {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
        }
    }
    
    // Helper functions
    private func weatherIcon(for condition: String) -> String {
        switch condition.lowercased() {
        case "sunny", "clear": return "sun.max.fill"
        case "cloudy": return "cloud.fill"
        case "rainy", "rain": return "cloud.rain.fill"
        case "snowy", "snow": return "cloud.snow.fill"
        case "stormy", "storm": return "cloud.bolt.fill"
        default: return "cloud.sun.fill"
        }
    }
    
    private func weatherColor(for condition: String) -> Color {
        switch condition.lowercased() {
        case "sunny", "clear": return .orange
        case "cloudy": return .gray
        case "rainy", "rain": return .blue
        case "snowy", "snow": return .white
        case "stormy", "storm": return .purple
        default: return .blue
        }
    }
    
    private func airQualityColor(for value: Double) -> Color {
        switch value {
        case 0..<25: return .green
        case 25..<50: return .yellow
        case 50..<75: return .orange
        case 75..<100: return .red
        default: return .purple
        }
    }
}

// MARK: - Weather Detail Item
struct WeatherDetailItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Air Quality Badge
struct AirQualityBadge: View {
    let aqi: Int
    let status: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(aqiColor)
                .frame(width: 8, height: 8)
            
            Text("\(aqi) - \(status)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(aqiColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(aqiColor.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var aqiColor: Color {
        switch aqi {
        case 0..<50: return .green
        case 50..<100: return .yellow
        case 100..<150: return .orange
        case 150..<200: return .red
        default: return .purple
        }
    }
}

// MARK: - Air Quality Item
struct AirQualityItem: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}


struct PointsCard: View {
    @State private var animate = false
    let points: Int
    
    var body: some View {
        HStack {
            // Left side: Heart + Points + Label
            HStack(spacing: 10) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.yellow)
                    .shadow(radius: 2)
                
                VStack(alignment: .leading, spacing: 7) {
                    Text("\(points)")
                        .font(.title)
                        .fontWeight(.bold)
                        .scaleEffect(animate ? 1.2 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true),
                            value: animate
                        )
                    
                    Text("Points you earned")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Right side
            Text("Keep it up!")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.green)
        }
        .padding()
        .frame(maxWidth: .infinity).frame(maxWidth: .infinity, minHeight: 100)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
        .onAppear {
            animate = true
        }
    }
}


// MARK: - Preview
#Preview {
    DashboardView()
        .environmentObject(SessionManager())
        .environmentObject(NavigationManager())
}
