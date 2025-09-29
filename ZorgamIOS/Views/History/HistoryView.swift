
import SwiftUI

// MARK: - History View
struct HistoryView: View {
    // MARK: - State
    @StateObject private var viewModel = HistoryViewModel()
    @State private var showingSortOptions = false
    @State private var refreshID = UUID()
    @State private var forceUpdate = 0
    @State private var currentSortOption: SortOption = .newestFirst
    
    // MARK: - Computed Properties
    private var sortedItems: [HistoryItem] {
        print("🔄 Computing sortedItems with \(viewModel.filteredHistoryItems.count) items")
        return viewModel.filteredHistoryItems
    }
    
    // MARK: - Body
    var body: some View {
        let _ = print("🔄 HistoryView body computed - filteredHistoryItems count: \(viewModel.filteredHistoryItems.count)")
        NavigationView {
            VStack(spacing: 0) {
                // Fixed Header Section
                VStack(spacing: 0) {
                    // Filter Section
                    FilterSection(
                        selectedFilter: $viewModel.selectedFilter,
                        onFilterSelected: { filter in
                            viewModel.selectFilter(filter)
                        }
                    )
                    .padding(.top, 8)
                    
                    // Sort Section
                    SortSection(
                        viewModel: viewModel,
                        currentSortOption: $currentSortOption,
                        showingSortOptions: $showingSortOptions
                    )
                }
                .background(Color(.systemBackground))
                
                // Scrollable Content Area
                if viewModel.isLoading {
                    LoadingView()
                } else if let errorMessage = viewModel.errorMessage {
                    ErrorStateView(errorMessage: errorMessage) {
                        Task {
                            await viewModel.refreshData()
                        }
                    }
                } else if viewModel.filteredHistoryItems.isEmpty {
                    EmptyStateView {
                        Task {
                            await viewModel.refreshData()
                        }
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(viewModel.filteredHistoryItems, id: \.id) { historyItem in
                                CheckInRecordCard(
                                    record: historyItem.record,
                                    submission: historyItem.submission
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .id("records-\(viewModel.filteredHistoryItems.count)-\(viewModel.selectedSort.rawValue)-\(refreshID)-\(forceUpdate)")
                    .refreshable {
                        await viewModel.refreshData()
                    }
                    .onAppear {
                        print("📱 RecordsListView appeared with \(viewModel.filteredHistoryItems.count) items")
                    }
                    .onChange(of: viewModel.filteredHistoryItems) { newItems in
                        print("📱 RecordsListView onChange: \(newItems.count) items")
                    }
                    .onChange(of: viewModel.selectedSort) { newSort in
                        print("📱 RecordsListView sort changed to: \(newSort.displayName)")
                        // Force UI update by changing the ID
                        refreshID = UUID()
                        forceUpdate += 1
                    }
                    .onChange(of: viewModel.selectedFilter) { newFilter in
                        print("📱 RecordsListView filter changed to: \(newFilter.displayName)")
                        // Force UI update by changing the ID
                        refreshID = UUID()
                        forceUpdate += 1
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            // Reset filter to "All" when navigating back to history page
            viewModel.selectedFilter = .all
            print("🔄 HistoryView appeared - reset filter to 'All'")
            
            Task {
                await viewModel.loadData(sortBy: viewModel.getSortByParameter(), sortOrder: viewModel.getSortOrderParameter())
            }
        }
        .sheet(isPresented: $showingSortOptions) {
            SortOptionsSheet(
                viewModel: viewModel,
                currentSortOption: $currentSortOption,
                isPresented: $showingSortOptions
            )
        }
    }
}

// MARK: - Filter Section
struct FilterSection: View {
    @Binding var selectedFilter: FilterType
    let onFilterSelected: (FilterType) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(FilterType.allCases, id: \.self) { filter in
                    FilterButton(
                        filter: filter,
                        isSelected: selectedFilter == filter,
                        action: {
                            onFilterSelected(filter)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .scrollIndicators(.hidden)
        .frame(height: 60)
        .clipped()
//        .background(Color.red)
        .scrollDisabled(false)
        .scrollBounceBehavior(.basedOnSize)
    }
}

// MARK: - Filter Button
struct FilterButton: View {
    let filter: FilterType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(filter.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.blue : Color(.systemGray5))
                )
        }
        .buttonStyle(PlainButtonStyle())
        .frame(minWidth: 60, maxWidth: 120)
        .fixedSize(horizontal: true, vertical: false)
        .contentShape(Rectangle())
    }
}

// MARK: - Sort Section
struct SortSection: View {
    let viewModel: HistoryViewModel
    @Binding var currentSortOption: SortOption
    @Binding var showingSortOptions: Bool
    
    var body: some View {
        HStack {
            Button(action: {
                showingSortOptions = true
            }) {
                HStack {
                    Text("Sort by: \(currentSortOption.displayName)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .id("sort-label-\(currentSortOption.rawValue)") // Force view update when sort changes
                        .onAppear {
                            print("🔄 SortSection UI updated - currentSortOption: \(currentSortOption.displayName)")
                        }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
            }
            .buttonStyle(PlainButtonStyle())
            .onChange(of: viewModel.selectedSort) { newSort in
                print("🔄 SortSection onChange triggered - newSort: \(newSort.displayName)")
                currentSortOption = newSort
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}


// MARK: - Check-in Record Card
struct CheckInRecordCard: View {
    let record: CheckInRecord
    let submission: SubmissionResponses?
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            if submission != nil {
                showingDetail = true
            }
        }) {
            HStack(spacing: 16) {
                // Calendar Icon
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 30, height: 30)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text("Check-in: \(record.type.displayName)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if let submission = submission {
                        Text("Submitted on: \(formatAPIDate(submission.submittedAt))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Submitted on: \(record.submittedAt, formatter: dateFormatter)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Status Badge - Use API status if available
                if let submission = submission {
                    StatusBadge(status: CheckInStatus.fromString(submission.status))
                } else {
                    StatusBadge(status: record.status)
                }
                
                // Navigation Arrow
                if submission != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            if let submission = submission {
                HistoryDetailView(submission: submission)
            }
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        return formatter
    }()
    
    private let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy 'at' h:mm a"
        return formatter
    }()
    
    private func formatAPIDate(_ dateString: String) -> String {
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: dateString) {
            return apiDateFormatter.string(from: date)
        } else {
            // Fallback to original string if parsing fails
            return dateString
        }
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: CheckInStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(statusColor)
            )
            .onAppear {
                print("🔍 StatusBadge displaying: \(status.displayName)")
            }
    }
    
    private var statusColor: Color {
        switch status {
        case .completed:
            return .green
        case .pending:
            return .orange
        case .inProgress:
            return .blue
        case .failed:
            return .red
        }
    }
}

// MARK: - Sort Options Sheet
struct SortOptionsSheet: View {
    let viewModel: HistoryViewModel
    @Binding var currentSortOption: SortOption
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(action: {
                        viewModel.selectSort(option)
                        currentSortOption = option
                        isPresented = false
                    }) {
                        HStack {
                            Text(option.displayName)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if currentSortOption == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Sort Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            
            VStack(spacing: 8) {
                Text("Loading History...")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Fetching your check-in records")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Error State View
struct ErrorStateView: View {
    let errorMessage: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64))
                .foregroundColor(.red)
            
            VStack(spacing: 8) {
                Text("Error Loading Data")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: onRetry) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red)
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 64))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("No Data Found")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("No check-in records found for the selected filter")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onRefresh) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue, lineWidth: 1)
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Preview
#Preview {
    HistoryView()
}
