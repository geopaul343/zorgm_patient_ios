import Foundation
import Combine

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
    func loadHistory() async {
        isLoading = true
        errorMessage = nil
        
        // For now, we'll use mock data since the API doesn't have a history endpoint yet
        // In the future, you can replace this with actual API calls
        await loadMockHistory()
    }
    
    private func loadMockHistory() async {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Mock history data
        let mockItems = [
            HistoryItem(
                id: "1",
                title: "Health Assessment Completed",
                description: "General health assessment",
                timestamp: Date().addingTimeInterval(-3600), // 1 hour ago
                icon: "checkmark.circle.fill",
                color: .green,
                status: "Completed"
            ),
            HistoryItem(
                id: "2",
                title: "Medication Added",
                description: "Added Metformin 500mg",
                timestamp: Date().addingTimeInterval(-7200), // 2 hours ago
                icon: "pills.fill",
                color: .blue,
                status: "Success"
            ),
            HistoryItem(
                id: "3",
                title: "Assessment Started",
                description: "Blood pressure assessment",
                timestamp: Date().addingTimeInterval(-10800), // 3 hours ago
                icon: "heart.fill",
                color: .red,
                status: "In Progress"
            ),
            HistoryItem(
                id: "4",
                title: "Profile Updated",
                description: "Updated personal information",
                timestamp: Date().addingTimeInterval(-86400), // 1 day ago
                icon: "person.fill",
                color: .purple,
                status: "Completed"
            ),
            HistoryItem(
                id: "5",
                title: "Medication Reminder",
                description: "Metformin reminder sent",
                timestamp: Date().addingTimeInterval(-172800), // 2 days ago
                icon: "bell.fill",
                color: .orange,
                status: "Sent"
            )
        ]
        
        historyItems = mockItems
        isLoading = false
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
