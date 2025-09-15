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
                        HealthSummaryCard(summary: summary)
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
                    
                    // Weather Card
                    if let weather = viewModel.weather {
                        WeatherCard(weather: weather)
                    }
                    
                    // Stats Grid
                    if let stats = viewModel.stats {
                        StatsGridView(stats: stats)
                    }
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Health Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("Score: \(Int(summary.healthScore))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            HStack(spacing: 20) {
                StatItem(
                    title: "Completed",
                    value: "\(summary.completedAssessments)",
                    color: .green
                )
                
                StatItem(
                    title: "Pending",
                    value: "\(summary.pendingAssessments)",
                    color: .orange
                )
                
                StatItem(
                    title: "Total",
                    value: "\(summary.totalAssessments)",
                    color: .blue
                )
            }
            
            if !summary.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommendations")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(summary.recommendations.prefix(2), id: \.self) { recommendation in
                        Text("• \(recommendation)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
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

// MARK: - Weather Card
struct WeatherCard: View {
    let weather: WeatherData
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Weather")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(weather.location)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("\(Int(weather.temperature))°C")
                    .font(.title)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: "cloud.sun.fill")
                    .font(.title)
                    .foregroundColor(.blue)
                
                Text(weather.condition)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(Int(weather.humidity))% humidity")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
}

// MARK: - Stats Grid View
struct StatsGridView: View {
    let stats: DashboardStats
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatItem(
                title: "Check-ins",
                value: "\(stats.totalCheckIns)",
                color: .blue
            )
            
            StatItem(
                title: "Weekly",
                value: "\(stats.weeklyAssessments)",
                color: .green
            )
            
            StatItem(
                title: "Monthly",
                value: "\(stats.monthlyAssessments)",
                color: .purple
            )
            
            StatItem(
                title: "Medications",
                value: "\(stats.medicationCount)",
                color: .orange
            )
        }
        .padding(.horizontal)
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Preview
#Preview {
    DashboardView()
        .environmentObject(SessionManager())
        .environmentObject(NavigationManager())
}
