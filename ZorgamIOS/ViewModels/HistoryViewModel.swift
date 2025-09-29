import Foundation
import Combine

// MARK: - History Item (Combined Record and Submission)
struct HistoryItem: Identifiable, Equatable {
    let id: String
    let record: CheckInRecord
    let submission: SubmissionResponses
    
    init(record: CheckInRecord, submission: SubmissionResponses) {
        self.record = record
        self.submission = submission
        // Use submission ID as the unique identifier
        self.id = "\(submission.id)"
    }
    
    // MARK: - Equatable
    static func == (lhs: HistoryItem, rhs: HistoryItem) -> Bool {
        return lhs.id == rhs.id && 
               lhs.record == rhs.record && 
               lhs.submission.id == rhs.submission.id
    }
}

// MARK: - History View Model
class HistoryViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var historyItems: [HistoryItem] = []
    @Published var filteredHistoryItems: [HistoryItem] = []
    @Published var selectedFilter: FilterType = .all
    @Published var selectedSort: SortOption = .newestFirst {
        didSet {
            print("🔄 selectedSort property changed from \(oldValue.displayName) to \(selectedSort.displayName)")
        }
    }
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let apiService = APIService()
    private var isLoadingData = false
    
    // MARK: - Initialization
    init() {
        setupSubscriptions()
        Task { @MainActor in
            print("🚀 Initial Task created for API call")
            await loadData(sortBy: getSortByParameter(), sortOrder: getSortOrderParameter())
        }
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Public Methods
    func loadData(sortBy: String? = nil, sortOrder: String? = nil) async {
        // Allow new API calls even if one is in progress (for sorting/filtering)
        if isLoadingData {
            print("⚠️ Previous API call in progress, but allowing new call for sorting/filtering...")
        }
        
        print("🚀 Starting API call to fetch questionnaire submissions...")
        print("🔧 Sort parameters: sortBy=\(sortBy ?? "none"), sortOrder=\(sortOrder ?? "none")")
        print("🎯 Current selectedSort: \(selectedSort.displayName)")
        print("📊 Expected order: \(getSortByParameter() ?? "none") \(getSortOrderParameter() ?? "none")")
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            isLoadingData = true
        }
        
        // Cancel any existing API subscriptions
        print("🔄 Canceling existing API subscriptions...")
        cancellables.removeAll()
        print("✅ Existing subscriptions canceled")
        
        // Call API to get questionnaire submissions with sorting
        print("🌐 Making API call with parameters: sortBy=\(sortBy ?? "none"), sortOrder=\(sortOrder ?? "none")")
        apiService.getSubmissions(aggregate: false, sortBy: sortBy, sortOrder: sortOrder)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    self.isLoadingData = false
                    
                    switch completion {
                    case .finished:
                        print("✅ API call completed successfully")
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                        print("❌ API Error: \(error.localizedDescription)")
                        print("📱 Falling back to mock data...")
                        self.loadMockData()
                    }
                },
                receiveValue: { [weak self] submissions in
                    guard let self = self else { return }
                    
                    print("✅ API Response received:")
                    print("📊 Total submissions: \(submissions.count)")
                    print("🔍 Raw API Response:")
                    print("=====================================")
                    
                    if submissions.isEmpty {
                        print("📭 No submissions found in API response")
                    } else {
                        // Print each submission with detailed formatting and order
                        print("📊 API Response Order Analysis:")
                        for (index, submission) in submissions.enumerated() {
                            print("📋 Submission \(index + 1):")
                            print("   🆔 ID: \(submission.id)")
                            print("   👤 User ID: \(submission.userId)")
                            print("   📝 Questionnaire ID: \(submission.questionnaireId)")
                            print("   📅 Checkin Type: \(submission.checkinType)")
                            print("   ⏰ Submitted at: \(submission.submittedAt)")
                            print("   ✅ Status: \(submission.status)")
                            print("   💬 Nurse Comments: \(submission.nurseComments ?? "None")")
                            
                            // Parse and display the actual date for sorting verification
                            let dateFormatter = ISO8601DateFormatter()
                            if let parsedDate = dateFormatter.date(from: submission.submittedAt) {
                                let displayFormatter = DateFormatter()
                                displayFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                                print("   📅 Parsed Date: \(displayFormatter.string(from: parsedDate))")
                            }
                            print("   📄 Answers JSON: \(submission.answersJson)")
                            print("   " + String(repeating: "-", count: 40))
                        }
                    }
                    
                    print("=====================================")
                    print("🔄 Converting API response to CheckInRecord objects...")
                    
                    // Convert API response to HistoryItems
                    self.convertSubmissionsToHistoryItems(submissions)
                    // No need to call applyFiltersAndSort() since data comes pre-sorted from server
                    
                    print("✅ Data processing completed")
                    print("📊 Final filtered history items count: \(self.filteredHistoryItems.count)")
                }
            )
            .store(in: &cancellables)
    }
    
    func refreshData() async {
        print("🔄 Refresh data called")
        await loadData(sortBy: getSortByParameter(), sortOrder: getSortOrderParameter())
    }
    
    func cancelAllRequests() {
        cancellables.removeAll()
        isLoadingData = false
        isLoading = false
    }
    
    func selectFilter(_ filter: FilterType) {
        print("🎯 Filter selected: \(filter.displayName)")
        selectedFilter = filter
        print("🔄 Applying client-side filter only - no API call")
        // Apply client-side filtering only
        applyFiltersAndSort()
    }
    
    func selectSort(_ sort: SortOption) {
        print("🎯 Sort selected: \(sort.displayName)")
        print("🔄 Before update - selectedSort: \(selectedSort.displayName)")
        
        // Update selectedSort on main thread to ensure UI updates
        DispatchQueue.main.async { [weak self] in
            self?.selectedSort = sort
            print("🔄 After update - selectedSort: \(self?.selectedSort.displayName ?? "nil")")
            print("🔄 Applying client-side sorting only - no API call")
            
            // Apply client-side sorting only
            self?.applyFiltersAndSort()
        }
    }
    
    // MARK: - Private Methods
    private func setupSubscriptions() {
        // No need for automatic sorting since we're doing server-side sorting
        // The subscription is removed to avoid conflicts with API calls
    }
    
    private func applyFiltersAndSort() {
        print("🔄 Applying client-side filters and sorting - Filter: \(selectedFilter), Sort: \(selectedSort)")
        
        var filtered = historyItems
        
        // Apply filter
        if selectedFilter != .all {
            filtered = filtered.filter { item in
                switch selectedFilter {
                case .all:
                    return true
                case .daily:
                    return item.record.type == .daily
                case .weekly:
                    return item.record.type == .weekly
                case .monthly:
                    return item.record.type == .monthly
                case .oneTime:
                    return item.record.type == .oneTime
                }
            }
        }
        
        // Apply client-side sorting
        applyClientSideSorting(&filtered)
        
        // Update filtered items
        print("🔄 Updating filteredHistoryItems from \(filteredHistoryItems.count) to \(filtered.count) items")
        filteredHistoryItems = Array(filtered)
        
        // Debug: Print current order
        print("📊 Client-side filtered and sorted \(filtered.count) items:")
        for (index, item) in filtered.enumerated() {
            let date = parseAPIDate(item.submission.submittedAt)
            print("  \(index + 1). \(item.record.type.displayName) - \(item.submission.submittedAt) (\(date))")
        }
    }
    
    private func parseAPIDate(_ dateString: String) -> Date {
        let iso8601Formatter = ISO8601DateFormatter()
        return iso8601Formatter.date(from: dateString) ?? Date()
    }
    
    func getSortByParameter() -> String? {
        let result: String?
        switch selectedSort {
        case .newestFirst, .oldestFirst:
            result = "submitted_at"
        case .typeAscending, .typeDescending:
            result = "checkin_type"
        }
        print("🔍 getSortByParameter() called with selectedSort: \(selectedSort.displayName) -> returning: \(result ?? "nil")")
        return result
    }
    
    func getSortOrderParameter() -> String? {
        let result: String?
        switch selectedSort {
        case .newestFirst, .typeDescending:
            result = "asc"  // Reversed: was "desc"
        case .oldestFirst, .typeAscending:
            result = "desc" // Reversed: was "asc"
        }
        print("🔍 getSortOrderParameter() called with selectedSort: \(selectedSort.displayName) -> returning: \(result ?? "nil")")
        return result
    }
    
    private func convertSubmissionsToHistoryItems(_ submissions: [SubmissionResponses]) {
        var items: [HistoryItem] = []
        
        for submission in submissions {
            // Parse the submitted date
            let dateFormatter = ISO8601DateFormatter()
            let submittedDate = dateFormatter.date(from: submission.submittedAt) ?? Date()
            
            // Determine check-in type based on checkinType field
            let checkInType = determineCheckInTypeFromString(submission.checkinType)
            
            // Determine status
            print("🔍 Processing submission \(submission.id) - API status: '\(submission.status)'")
            let status = determineCheckInStatus(from: submission.status)
            print("🔍 Mapped to CheckInStatus: \(status.displayName)")
            
            // Create CheckInRecord
            let record = CheckInRecord(
                type: checkInType,
                submittedAt: submittedDate,
                status: status,
                responses: submission.answersJson
            )
            
            // Create HistoryItem that combines record and submission
            let historyItem = HistoryItem(record: record, submission: submission)
            items.append(historyItem)
        }
        
        historyItems = items
        // Since data comes pre-sorted from server, set filteredHistoryItems directly
        filteredHistoryItems = items
        print("✅ Converted \(items.count) API submissions to HistoryItems")
        print("📊 Server-sorted data loaded directly into filteredHistoryItems")
        
        // Debug: Print the final order to verify sorting
        print("🔍 Final Order Verification:")
        for (index, item) in items.enumerated() {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            print("  \(index + 1). \(item.record.type.displayName) - \(dateFormatter.string(from: item.record.submittedAt))")
        }
        
        // Check if sorting is correct, if not, apply client-side sorting as fallback
        if !isDataCorrectlySorted(items) {
            print("⚠️ Server-side sorting not working, applying client-side sorting as fallback")
            applyClientSideSorting(&items)
            filteredHistoryItems = items
        }
    }
    
    private func isDataCorrectlySorted(_ items: [HistoryItem]) -> Bool {
        guard items.count > 1 else { return true }
        
        switch selectedSort {
        case .newestFirst:
            // Check if dates are in ascending order (newest first - reversed)
            for i in 0..<(items.count - 1) {
                if items[i].record.submittedAt > items[i + 1].record.submittedAt {  // Reversed: was <
                    print("❌ Sorting incorrect: item \(i) (\(items[i].record.submittedAt)) should be before item \(i + 1) (\(items[i + 1].record.submittedAt))")
                    return false
                }
            }
        case .oldestFirst:
            // Check if dates are in descending order (oldest first - reversed)
            for i in 0..<(items.count - 1) {
                if items[i].record.submittedAt < items[i + 1].record.submittedAt {  // Reversed: was >
                    print("❌ Sorting incorrect: item \(i) (\(items[i].record.submittedAt)) should be after item \(i + 1) (\(items[i + 1].record.submittedAt))")
                    return false
                }
            }
        case .typeAscending:
            // Check if types are in descending order (reversed)
            for i in 0..<(items.count - 1) {
                if items[i].record.type.displayName < items[i + 1].record.type.displayName {  // Reversed: was >
                    print("❌ Sorting incorrect: type \(items[i].record.type.displayName) should be before \(items[i + 1].record.type.displayName)")
                    return false
                }
            }
        case .typeDescending:
            // Check if types are in ascending order (reversed)
            for i in 0..<(items.count - 1) {
                if items[i].record.type.displayName > items[i + 1].record.type.displayName {  // Reversed: was <
                    print("❌ Sorting incorrect: type \(items[i].record.type.displayName) should be after \(items[i + 1].record.type.displayName)")
                    return false
                }
            }
        }
        
        print("✅ Data is correctly sorted")
        return true
    }
    
    private func applyClientSideSorting(_ items: inout [HistoryItem]) {
        print("🔄 Applying client-side sorting for: \(selectedSort.displayName)")
        print("🔍 Current selectedSort in applyClientSideSorting: \(selectedSort.displayName)")
        
        items.sort { item1, item2 in
            switch selectedSort {
            case .newestFirst:
                let result = item1.record.submittedAt < item2.record.submittedAt  // Reversed: was >
                print("🔍 newestFirst: \(item1.record.submittedAt) < \(item2.record.submittedAt) = \(result)")
                return result
            case .oldestFirst:
                let result = item1.record.submittedAt > item2.record.submittedAt  // Reversed: was <
                print("🔍 oldestFirst: \(item1.record.submittedAt) > \(item2.record.submittedAt) = \(result)")
                return result
            case .typeAscending:
                let result = item1.record.type.displayName > item2.record.type.displayName  // Reversed: was <
                print("🔍 typeAscending: \(item1.record.type.displayName) > \(item2.record.type.displayName) = \(result)")
                return result
            case .typeDescending:
                let result = item1.record.type.displayName < item2.record.type.displayName  // Reversed: was >
                print("🔍 typeDescending: \(item1.record.type.displayName) < \(item2.record.type.displayName) = \(result)")
                return result
            }
        }
        
        print("✅ Client-side sorting applied")
    }
    
    private func determineCheckInTypeFromString(_ checkinType: String) -> CheckInType {
        switch checkinType.uppercased() {
        case "DAILY":
            return .daily
        case "WEEKLY":
            return .weekly
        case "MONTHLY":
            return .monthly
        case "ONE_TIME":
            return .oneTime
        default:
            return .oneTime
        }
    }
    
    private func determineCheckInType(from questionnaireName: String) -> CheckInType {
        let name = questionnaireName.lowercased()
        
        if name.contains("daily") {
            return .daily
        } else if name.contains("weekly") {
            return .weekly
        } else if name.contains("monthly") {
            return .monthly
        } else {
            return .oneTime
        }
    }
    
    private func determineCheckInStatus(from status: String) -> CheckInStatus {
        switch status.lowercased() {
        case "completed", "submitted":
            return .completed
        case "pending", "pending_review":
            return .pending
        case "in_progress", "in progress":
            return .inProgress
        case "failed", "error":
            return .failed
        default:
            return .completed
        }
    }
    
    
    private func loadMockData() {
        print("📱 Loading mock data as fallback...")
        let calendar = Calendar.current
        let now = Date()
        
        // Generate mock data for the past 30 days
        var mockRecords: [CheckInRecord] = []
        
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            
            // Add daily check-ins (every day)
            if i % 1 == 0 {
                mockRecords.append(CheckInRecord(
                    type: .daily,
                    submittedAt: calendar.date(byAdding: .hour, value: Int.random(in: 6...18), to: date) ?? date,
                    status: .completed
                ))
            }
            
            // Add weekly check-ins (every 7 days)
            if i % 7 == 0 {
                mockRecords.append(CheckInRecord(
                    type: .weekly,
                    submittedAt: calendar.date(byAdding: .hour, value: Int.random(in: 9...17), to: date) ?? date,
                    status: .completed
                ))
            }
            
            // Add monthly check-ins (every 15 days)
            if i % 15 == 0 {
                mockRecords.append(CheckInRecord(
                    type: .monthly,
                    submittedAt: calendar.date(byAdding: .hour, value: Int.random(in: 10...16), to: date) ?? date,
                    status: .completed
                ))
            }
            
            // Add one-time check-ins (randomly)
            if i % 10 == 0 {
                mockRecords.append(CheckInRecord(
                    type: .oneTime,
                    submittedAt: calendar.date(byAdding: .hour, value: Int.random(in: 8...20), to: date) ?? date,
                    status: .completed
                ))
            }
        }
        
        // Convert mock records to history items
        var mockHistoryItems: [HistoryItem] = []
        for record in mockRecords {
            // Create a mock submission for each record
            let mockSubmission = SubmissionResponses(
                id: Int.random(in: 1000...9999),
                userId: 1,
                questionnaireId: 1,
                checkinType: record.type.rawValue.uppercased(),
                answersJson: record.responses,
                status: record.status.rawValue,
                nurseComments: "Mock nurse comment",
                submittedAt: ISO8601DateFormatter().string(from: record.submittedAt),
                createdAt: ISO8601DateFormatter().string(from: record.submittedAt),
                updatedAt: ISO8601DateFormatter().string(from: record.submittedAt),
                alertLevel: "low",
                diseaseId: 1,
                diseaseName: "COPD",
                reviewedByNurseId: 1,
                reviewedAt: ISO8601DateFormatter().string(from: record.submittedAt),
                user: "Mock User",
                reviewedByNurse: "Mock Nurse"
            )
            let historyItem = HistoryItem(record: record, submission: mockSubmission)
            mockHistoryItems.append(historyItem)
        }
        
        historyItems = mockHistoryItems
        applyFiltersAndSort()
        print("✅ Mock data loaded: \(mockHistoryItems.count) history items")
    }
    
    // MARK: - Computed Properties
    var totalRecords: Int {
        historyItems.count
    }
    
    var filteredRecordsCount: Int {
        filteredHistoryItems.count
    }
    
    var recordsByType: [CheckInType: Int] {
        Dictionary(grouping: historyItems, by: { $0.record.type })
            .mapValues { $0.count }
    }
}
