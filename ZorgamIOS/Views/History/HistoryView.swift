
import SwiftUI

// MARK: - History View
struct HistoryView: View {
    // MARK: - State
    @StateObject private var viewModel = HistoryViewModel()
    @State private var showingSortOptions = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Section
                FilterSection(
                    selectedFilter: $viewModel.selectedFilter,
                    onFilterSelected: { filter in
                        viewModel.selectFilter(filter)
                    }
                )
                
                // Sort Section
                SortSection(
                    selectedSort: $viewModel.selectedSort,
                    showingSortOptions: $showingSortOptions
                )
                
                // Records List
                if viewModel.isLoading {
                    LoadingView()
                } else if let errorMessage = viewModel.errorMessage {
                    ErrorStateView(errorMessage: errorMessage) {
                        Task {
                            await viewModel.refreshData()
                        }
                    }
                } else if viewModel.filteredRecords.isEmpty {
                    EmptyStateView {
                        Task {
                            await viewModel.refreshData()
                        }
                    }
                } else {
                    RecordsListView(records: viewModel.filteredRecords)
                }
            }
            .navigationTitle("History")
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
        .sheet(isPresented: $showingSortOptions) {
            SortOptionsSheet(
                selectedSort: $viewModel.selectedSort,
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
        ScrollView(.horizontal, showsIndicators: true) {
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
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
        .frame(height: 50)
        .clipped()
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
    }
}

// MARK: - Sort Section
struct SortSection: View {
    @Binding var selectedSort: SortOption
    @Binding var showingSortOptions: Bool
    
    var body: some View {
        HStack {
            Button(action: {
                showingSortOptions = true
            }) {
                HStack {
                    Text("Sort by: \(selectedSort.displayName)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
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
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Records List View
struct RecordsListView: View {
    let records: [CheckInRecord]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(records) { record in
                    CheckInRecordCard(record: record)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Check-in Record Card
struct CheckInRecordCard: View {
    let record: CheckInRecord
    
    var body: some View {
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
                
                Text("Submitted on: \(record.submittedAt, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status Badge
            StatusBadge(status: record.status)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        return formatter
    }()
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
    @Binding var selectedSort: SortOption
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(action: {
                        selectedSort = option
                        isPresented = false
                    }) {
                        HStack {
                            Text(option.displayName)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedSort == option {
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
