import SwiftUI

// MARK: - History View
struct HistoryView: View {
    // MARK: - Environment Objects
    @EnvironmentObject private var sessionManager: SessionManager
    
    // MARK: - State Properties
    @StateObject private var viewModel = HistoryViewModel()
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading history...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.historyItems.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No History Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Your activity history will appear here")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.historyItems) { item in
                            HistoryItemRow(item: item)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.loadHistory()
            }
        }
        .onAppear {
            Task {
                await viewModel.loadHistory()
            }
        }
    }
}

// MARK: - History Item Row
struct HistoryItemRow: View {
    let item: HistoryItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: item.icon)
                .font(.title2)
                .foregroundColor(item.color)
                .frame(width: 30, height: 30)
                .background(item.color.opacity(0.1))
                .clipShape(Circle())
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(item.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(item.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status indicator
            if let status = item.status {
                Text(status)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(for: status).opacity(0.2))
                    .foregroundColor(statusColor(for: status))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
    
    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "completed", "success":
            return .green
        case "pending", "in progress":
            return .orange
        case "failed", "error":
            return .red
        default:
            return .blue
        }
    }
}

// MARK: - Preview
#Preview {
    HistoryView()
        .environmentObject(SessionManager())
}
