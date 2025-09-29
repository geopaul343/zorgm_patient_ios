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
                    if let stats = viewModel.stats {
                        HealthSummaryCard(stats: stats, isLoading: viewModel.isLoading)
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
                        WeatherAirQualityCard(weather: weather)
                    } else {
                        // Show loading state for air quality and pollen
                        VStack(spacing: 20) {
                            HStack {
                                Text("Air Quality & Pollen")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Spacer()
                                
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Updated: \(formattedCurrentTime())")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal)
                            
                            if viewModel.isLoading {
                                VStack(spacing: 12) {
                                    Text("Fetching latest air quality and pollen data...")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(1.2)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                Text("No data available")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        .padding(.horizontal)
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
                    PointsCard(points: viewModel.totalPoints)
                    
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refreshData()
            }
        }
        .overlay(
            // Confetti and Points Popup overlay
            ZStack {
                // Confetti overlay
                if viewModel.showConfetti {
                    ConfettiView()
                        .allowsHitTesting(false)
                }
                
                // Points popup overlay
                if viewModel.showPointsPopup {
                    VStack {
                        Spacer()
                        PointsPopupView(points: viewModel.pointsEarned)
                            .padding(.bottom, 100)
                    }
                    .allowsHitTesting(false)
                }
            }
        )
        .onAppear {
            Task {
                await viewModel.loadData()
            }
            // Start auto-refresh timer for weather data
            viewModel.startAutoRefresh()
        }
        .onDisappear {
            // Stop auto-refresh timer when view disappears
            viewModel.stopAutoRefresh()
        }
    }
}

// MARK: - Health Summary Card
struct HealthSummaryCard: View {
    let stats: DashboardStats
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
                 SummaryItem(icon: "heart.fill", number: stats.dailyCheckIns, label: "Daily", color: .red)
                 Spacer()
                 SummaryItem(icon: "chart.bar.fill", number: stats.weeklyAssessments, label: "Weekly", color: .blue)
                 Spacer()
                 SummaryItem(icon: "calendar", number: stats.monthlyAssessments, label: "Monthly", color: .green)
             }
             .padding(.horizontal)
             
             // Total Submission in one row
             HStack(spacing: 8) {
                 Text("Total Submission")
                     .font(.headline)
                 Text("\(stats.totalCheckIns)")
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
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Air Quality & Pollen")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Updated: \(formattedDate(from: weather.timestamp))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(weather.location)
                        .font(.caption)
                        .foregroundColor(.secondary)
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
            
            // Pollen Section
            if let pollen = weather.pollen {
                VStack(spacing: 12) {
                    HStack {
                        Text("Pollen Count")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("Today")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Pollen Details
                    HStack(spacing: 16) {
                        PollenItem(
                            label: "Grass",
                            value: "\(pollen.grassPollen)",
                            risk: pollen.grassPollenRisk,
                            color: pollenColor(for: pollen.grassPollenRisk)
                        )
                        PollenItem(
                            label: "Tree",
                            value: "\(pollen.treePollen)",
                            risk: pollen.treePollenRisk,
                            color: pollenColor(for: pollen.treePollenRisk)
                        )
                        PollenItem(
                            label: "Ragweed",
                            value: "\(pollen.ragweedPollen)",
                            risk: pollen.ragweedPollenRisk,
                            color: pollenColor(for: pollen.ragweedPollenRisk)
                        )
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
    }
    
    // Helper functions
    
    private func airQualityColor(for value: Double) -> Color {
        switch value {
        case 0..<25: return .green
        case 25..<50: return .yellow
        case 50..<75: return .orange
        case 75..<100: return .red
        default: return .purple
        }
    }
    
    private func pollenColor(for risk: String) -> Color {
        switch risk.lowercased() {
        case "low": return .green
        case "moderate": return .yellow
        case "high": return .orange
        case "very high": return .red
        default: return .gray
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

// MARK: - Pollen Item
struct PollenItem: View {
    let label: String
    let value: String
    let risk: String
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
            
            Text(risk)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(color)
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


// MARK: - Helper Functions
private func formattedCurrentTime() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    return formatter.string(from: Date())
}

private func formattedDate(from timestamp: String) -> String {
    let formatter = ISO8601DateFormatter()
    if let date = formatter.date(from: timestamp) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.string(from: date)
    }
    return "N/A"
}

// MARK: - Confetti View
struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<50, id: \.self) { index in
                Circle()
                    .fill(colors.randomElement() ?? .red)
                    .frame(width: 8, height: 8)
                    .offset(
                        x: animate ? CGFloat.random(in: -200...200) : 0,
                        y: animate ? CGFloat.random(in: -400...400) : -50
                    )
                    .opacity(animate ? 0 : 1)
                    .animation(
                        Animation.easeOut(duration: Double.random(in: 2...4))
                            .delay(Double.random(in: 0...1))
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
    
    private let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
}

// MARK: - Points Popup View
struct PointsPopupView: View {
    let points: Int
    @State private var animate = false
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        VStack(spacing: 12) {
            // Points icon
            Image(systemName: "star.fill")
                .font(.system(size: 40))
                .foregroundColor(.yellow)
                .scaleEffect(animate ? 1.2 : 0.8)
                .animation(
                    Animation.easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true),
                    value: animate
                )
            
            // Points text
            VStack(spacing: 4) {
                Text("+\(points)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .scaleEffect(animate ? 1.1 : 0.9)
                    .animation(
                        Animation.easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true),
                        value: animate
                    )
                
                Text("Points Earned!")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        )
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                scale = 1.0
                opacity = 1.0
            }
            
            withAnimation(.easeInOut(duration: 0.5).delay(0.2)) {
                animate = true
            }
        }
    }
}

// MARK: - Preview
#Preview {
    DashboardView()
        .environmentObject(SessionManager())
        .environmentObject(NavigationManager())
}
