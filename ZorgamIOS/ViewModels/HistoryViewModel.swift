import Foundation
import Combine
import SwiftUI

// MARK: - Filter Type Enum
enum FilterType: String, CaseIterable {
    case daily, weekly, monthly, onetime
}

// MARK: - History View Model
class HistoryViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var historyItems: [HistoryItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let apiService = APIService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    @MainActor
    func loadHistory(for filter: FilterType = .daily) async {
        isLoading = true
        errorMessage = nil
        
        // For now, we'll use mock data since the API doesn't have a history endpoint yet
        // In the future, you can replace this with actual API calls
        await loadMockHistory(for: filter)
    }
    
    @MainActor
    func loadHistory() async {
        await loadHistory(for: .daily)
    }
    
    private func loadMockHistory(for filter: FilterType = .daily) async {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
        
        // Mock history data based on filter
        let mockItems = getMockData(for: filter)
        
        historyItems = mockItems
        isLoading = false
    }
    
    private func getMockData(for filter: FilterType) -> [HistoryItem] {
        switch filter {
        case .daily:
            return [
                HistoryItem(
                    id: "daily_1",
                    title: "Morning Check-in",
                    description: "Daily health assessment completed",
                    timestamp: Date().addingTimeInterval(-3600), // 1 hour ago
                    icon: "sun.max.fill",
                    color: .orange,
                    status: "Completed"
                ),
                HistoryItem(
                    id: "daily_2",
                    title: "Medication Taken",
                    description: "Metformin 500mg taken",
                    timestamp: Date().addingTimeInterval(-7200), // 2 hours ago
                    icon: "pills.fill",
                    color: .blue,
                    status: "Success"
                ),
                HistoryItem(
                    id: "daily_3",
                    title: "Exercise Logged",
                    description: "30 minutes walking recorded",
                    timestamp: Date().addingTimeInterval(-10800), // 3 hours ago
                    icon: "figure.walk",
                    color: .green,
                    status: "Completed"
                )
            ]
            
        case .weekly:
            return [
                HistoryItem(
                    id: "weekly_1",
                    title: "Weekly Health Report",
                    description: "Summary of the past 7 days",
                    timestamp: Date().addingTimeInterval(-86400), // 1 day ago
                    icon: "chart.bar.fill",
                    color: .blue,
                    status: "Generated"
                ),
                HistoryItem(
                    id: "weekly_2",
                    title: "Medication Review",
                    description: "Weekly medication adherence check",
                    timestamp: Date().addingTimeInterval(-172800), // 2 days ago
                    icon: "pills.circle.fill",
                    color: .purple,
                    status: "Completed"
                ),
                HistoryItem(
                    id: "weekly_3",
                    title: "Progress Update",
                    description: "Health goals progress review",
                    timestamp: Date().addingTimeInterval(-259200), // 3 days ago
                    icon: "target",
                    color: .green,
                    status: "On Track"
                )
            ]
            
        case .monthly:
            return [
                HistoryItem(
                    id: "monthly_1",
                    title: "Monthly Health Assessment",
                    description: "Comprehensive monthly health review",
                    timestamp: Date().addingTimeInterval(-604800), // 1 week ago
                    icon: "calendar.badge.checkmark",
                    color: .green,
                    status: "Completed"
                ),
                HistoryItem(
                    id: "monthly_2",
                    title: "Doctor Consultation",
                    description: "Monthly checkup with Dr. Smith",
                    timestamp: Date().addingTimeInterval(-1209600), // 2 weeks ago
                    icon: "stethoscope",
                    color: .blue,
                    status: "Scheduled"
                ),
                HistoryItem(
                    id: "monthly_3",
                    title: "Lab Results",
                    description: "Blood test results received",
                    timestamp: Date().addingTimeInterval(-1814400), // 3 weeks ago
                    icon: "testtube.2",
                    color: .red,
                    status: "Available"
                )
            ]
            
        case .onetime:
            return [
                HistoryItem(
                    id: "onetime_1",
                    title: "Initial Health Setup",
                    description: "First-time health profile creation",
                    timestamp: Date().addingTimeInterval(-2592000), // 1 month ago
                    icon: "person.badge.plus",
                    color: .purple,
                    status: "Completed"
                ),
                HistoryItem(
                    id: "onetime_2",
                    title: "Emergency Contact Added",
                    description: "Emergency contact information updated",
                    timestamp: Date().addingTimeInterval(-3456000), // 1.5 months ago
                    icon: "phone.circle.fill",
                    color: .orange,
                    status: "Updated"
                ),
                HistoryItem(
                    id: "onetime_3",
                    title: "Privacy Settings",
                    description: "Data privacy preferences configured",
                    timestamp: Date().addingTimeInterval(-4320000), // 2 months ago
                    icon: "lock.shield.fill",
                    color: .gray,
                    status: "Configured"
                )
            ]
        }
    }
    
    func refreshHistory() {
        Task {
            await loadHistory()
        }
    }
}

// MARK: - History Item Model
struct HistoryItem: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let timestamp: Date
    let icon: String
    let color: Color
    let status: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, timestamp, icon, status
    }
    
    init(id: String, title: String, description: String, timestamp: Date, icon: String, color: Color, status: String?) {
        self.id = id
        self.title = title
        self.description = description
        self.timestamp = timestamp
        self.icon = icon
        self.color = color
        self.status = status
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        icon = try container.decode(String.self, forKey: .icon)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        
        // For now, we'll use a default color since Color doesn't conform to Codable
        // In a real app, you'd store the color as a string or use a different approach
        self.color = .blue
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(icon, forKey: .icon)
        try container.encodeIfPresent(status, forKey: .status)
    }
}
