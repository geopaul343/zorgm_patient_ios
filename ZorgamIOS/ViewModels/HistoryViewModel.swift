import Foundation
import Combine

// MARK: - History View Model
class HistoryViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var checkInRecords: [CheckInRecord] = []
    @Published var filteredRecords: [CheckInRecord] = []
    @Published var selectedFilter: FilterType = .all
    @Published var selectedSort: SortOption = .newestFirst
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let apiService = APIService()
    private var isLoadingData = false
    
    // MARK: - Initialization
    init() {
        setupSubscriptions()
        Task {
            await loadData()
        }
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Public Methods
    func loadData() async {
        // Prevent multiple simultaneous API calls
        guard !isLoadingData else {
            print("⚠️ API call already in progress, skipping...")
            return
        }
        
        print("🚀 Starting API call to fetch questionnaire submissions...")
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            isLoadingData = true
        }
        
        // Cancel any existing API subscriptions
        cancellables.removeAll()
        
        // Call API to get questionnaire submissions
        apiService.getSubmissions(aggregate: false)
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
                        // Print each submission with detailed formatting
                        for (index, submission) in submissions.enumerated() {
                            print("📋 Submission \(index + 1):")
                            print("   🆔 ID: \(submission.id)")
                            print("   👤 User ID: \(submission.userId)")
                            print("   📝 Questionnaire ID: \(submission.questionnaireId)")
                            print("   📅 Checkin Type: \(submission.checkinType)")
                            print("   ⏰ Submitted at: \(submission.submittedAt)")
                            print("   ✅ Status: \(submission.status)")
                            print("   💬 Nurse Comments: \(submission.nurseComments ?? "None")")
                            print("   📄 Answers JSON: \(submission.answersJson)")
                            print("   " + String(repeating: "-", count: 40))
                        }
                    }
                    
                    print("=====================================")
                    print("🔄 Converting API response to CheckInRecord objects...")
                    
                    // Convert API response to CheckInRecord
                    self.convertSubmissionsToCheckInRecords(submissions)
                    self.applyFiltersAndSort()
                    
                    print("✅ Data processing completed")
                    print("📊 Final filtered records count: \(self.filteredRecords.count)")
                }
            )
            .store(in: &cancellables)
    }
    
    func refreshData() async {
        await loadData()
    }
    
    func cancelAllRequests() {
        cancellables.removeAll()
        isLoadingData = false
        isLoading = false
    }
    
    func selectFilter(_ filter: FilterType) {
        selectedFilter = filter
        applyFiltersAndSort()
    }
    
    func selectSort(_ sort: SortOption) {
        selectedSort = sort
        applyFiltersAndSort()
    }
    
    // MARK: - Private Methods
    private func setupSubscriptions() {
        $checkInRecords
            .combineLatest($selectedFilter, $selectedSort)
            .sink { [weak self] _, _, _ in
                self?.applyFiltersAndSort()
            }
            .store(in: &cancellables)
    }
    
    private func applyFiltersAndSort() {
        var filtered = checkInRecords
        
        // Apply filter
        if selectedFilter != .all {
            filtered = filtered.filter { record in
                switch selectedFilter {
                case .all:
                    return true
                case .daily:
                    return record.type == .daily
                case .weekly:
                    return record.type == .weekly
                case .monthly:
                    return record.type == .monthly
                case .oneTime:
                    return record.type == .oneTime
                }
            }
        }
        
        // Apply sort
        filtered.sort { record1, record2 in
            switch selectedSort {
            case .newestFirst:
                return record1.submittedAt > record2.submittedAt
            case .oldestFirst:
                return record1.submittedAt < record2.submittedAt
            case .typeAscending:
                return record1.type.displayName < record2.type.displayName
            case .typeDescending:
                return record1.type.displayName > record2.type.displayName
            }
        }
        
        filteredRecords = filtered
    }
    
    private func convertSubmissionsToCheckInRecords(_ submissions: [SubmissionResponse]) {
        var records: [CheckInRecord] = []
        
        for submission in submissions {
            // Parse the submitted date
            let dateFormatter = ISO8601DateFormatter()
            let submittedDate = dateFormatter.date(from: submission.submittedAt) ?? Date()
            
            // Determine check-in type based on checkinType field
            let checkInType = determineCheckInTypeFromString(submission.checkinType)
            
            // Determine status
            let status = determineCheckInStatus(from: submission.status)
            
            // Create CheckInRecord
            let record = CheckInRecord(
                type: checkInType,
                submittedAt: submittedDate,
                status: status,
                responses: submission.answersJson
            )
            
            records.append(record)
        }
        
        checkInRecords = records
        print("✅ Converted \(records.count) API submissions to CheckInRecords")
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
        case "pending":
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
        
        checkInRecords = mockRecords
        applyFiltersAndSort()
        print("✅ Mock data loaded: \(mockRecords.count) records")
    }
    
    // MARK: - Computed Properties
    var totalRecords: Int {
        checkInRecords.count
    }
    
    var filteredRecordsCount: Int {
        filteredRecords.count
    }
    
    var recordsByType: [CheckInType: Int] {
        Dictionary(grouping: checkInRecords, by: { $0.type })
            .mapValues { $0.count }
    }
}
