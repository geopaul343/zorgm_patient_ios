import SwiftUI

// MARK: - Assessments View
struct AssessmentsView: View {
    // MARK: - Environment Objects
    @EnvironmentObject private var navigationManager: NavigationManager
    
    // MARK: - State
    @StateObject private var viewModel = AssessmentsViewModel()
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Group {
                if let selectedType = navigationManager.selectedAssessmentType {
                    // Show specific assessment view (from dashboard navigation)
                    assessmentView(for: selectedType)
                } else {
                    // Always show daily assessment view when Assessments tab is selected
                    DailyAssessmentView()
                }
            }
            .navigationTitle(navigationManager.selectedAssessmentType?.displayName ?? "Daily Check-in")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if navigationManager.selectedAssessmentType != nil {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Back") {
                            navigationManager.selectedAssessmentType = nil
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadData()
            }
        }
    }
    
    // MARK: - Assessment List View
    private var assessmentListView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Health Assessments")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Complete your health check-ins to track your progress")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Assessment Types
                LazyVStack(spacing: 16) {
                    ForEach(AssessmentType.allCases, id: \.self) { type in
                        AssessmentCard(
                            type: type,
                            isCompleted: viewModel.isAssessmentCompleted(type),
                            lastCompleted: viewModel.getLastCompletedDate(type),
                            onTap: {
                                navigationManager.navigateToAssessment(type)
                            }
                        )
                    }
                }
                .padding(.horizontal)
                
                // Recent Activity
                if !viewModel.recentActivity.isEmpty {
                    RecentActivityView(activities: viewModel.recentActivity)
                }
            }
            .padding(.bottom, 20)
        }
        .refreshable {
            await viewModel.refreshData()
        }
    }
    
    // MARK: - Assessment View for Type
    @ViewBuilder
    private func assessmentView(for type: AssessmentType) -> some View {
        switch type {
        case .daily:
            DailyAssessmentView()
        case .weekly:
            WeeklyAssessmentView()
        case .monthly:
            MonthlyAssessmentView()
        }
    }
}

// MARK: - Assessment Card
struct AssessmentCard: View {
    let type: AssessmentType
    let isCompleted: Bool
    let lastCompleted: Date?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(backgroundColor)
                    .clipShape(Circle())
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    if isCompleted, let lastCompleted = lastCompleted {
                        Text("Last completed: \(lastCompleted, formatter: dateFormatter)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Not completed yet")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                // Status Indicator
                VStack {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isCompleted ? .green : .gray)
                    
                    if isCompleted {
                        Text("Done")
                            .font(.caption2)
                            .foregroundColor(.green)
                    } else {
                        Text("Pending")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var backgroundColor: Color {
        switch type {
        case .daily: return .orange
        case .weekly: return .green
        case .monthly: return .purple
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Recent Activity View
struct RecentActivityView: View {
    let activities: [AssessmentActivity]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            LazyVStack(spacing: 12) {
                ForEach(activities) { activity in
                    ActivityRow(activity: activity)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Activity Row
struct ActivityRow: View {
    let activity: AssessmentActivity
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.type.icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30, height: 30)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.type.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(activity.completedAt, formatter: dateFormatter)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(.green)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Assessment Activity Model
struct AssessmentActivity: Identifiable {
    let id = UUID()
    let type: AssessmentType
    let completedAt: Date
}

// MARK: - Preview
#Preview {
    AssessmentsView()
        .environmentObject(NavigationManager())
}
