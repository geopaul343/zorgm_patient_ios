import SwiftUI

// MARK: - Medications View
struct MedicationsView: View {
    // MARK: - Environment Objects
    @EnvironmentObject private var navigationManager: NavigationManager
    
    // MARK: - State
    @StateObject private var viewModel = MedicationsViewModel()
    @State private var showingAddMedication = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    ProgressView("Loading medications...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.medications.isEmpty {
                    EmptyMedicationsView {
                        showingAddMedication = true
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.medications) { medication in
                                MedicationCard(
                                    medication: medication,
                                    onEdit: {
                                        // Handle edit
                                    },
                                    onDelete: {
                                        viewModel.deleteMedication(medication)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Medications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddMedication = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMedication) {
                AddMedicationView { medication in
                    viewModel.addMedication(medication)
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .onAppear {
            Task {
                await viewModel.loadMedications()
            }
        }
    }
}

// MARK: - Empty Medications View
struct EmptyMedicationsView: View {
    let onAddMedication: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "pills.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.6))
            
            Text("No Medications")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add your medications to track them easily")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: onAddMedication) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Medication")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
        }
        .padding()
    }
}

// MARK: - Medication Card
struct MedicationCard: View {
    let medication: Medication
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(medication.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(medication.dosage) • \(medication.frequency)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Menu {
                    Button("Edit", action: onEdit)
                    Button("Delete", role: .destructive, action: {
                        showingDeleteAlert = true
                    })
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }
            
            if let instructions = medication.instructions, !instructions.isEmpty {
                Text(instructions)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Start Date")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(formatDate(medication.startDate))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                if let endDate = medication.endDate {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("End Date")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(formatDate(endDate))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Status")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(medication.isActive ? "Active" : "Inactive")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(medication.isActive ? .green : .red)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .alert("Delete Medication", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive, action: onDelete)
        } message: {
            Text("Are you sure you want to delete \(medication.name)?")
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    
    private func formatDate(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: dateString) {
            return dateFormatter.string(from: date)
        }
        return dateString
    }
}

// MARK: - Add Medication View
struct AddMedicationView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onSave: (AddMedicationRequest) -> Void
    
    @State private var name = ""
    @State private var dosage = ""
    @State private var frequency = ""
    @State private var instructions = ""
    @State private var startDate = Date()
    @State private var endDate: Date?
    @State private var hasEndDate = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Medication Details") {
                    TextField("Medication Name", text: $name)
                    TextField("Dosage", text: $dosage)
                    TextField("Frequency", text: $frequency)
                }
                
                Section("Instructions") {
                    TextField("Instructions (optional)", text: $instructions, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Dates") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    
                    Toggle("Has End Date", isOn: $hasEndDate)
                    
                    if hasEndDate {
                        DatePicker("End Date", selection: Binding(
                            get: { endDate ?? Date() },
                            set: { endDate = $0 }
                        ), displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let medication = AddMedicationRequest(
                            name: name,
                            dosage: dosage,
                            frequency: frequency,
                            instructions: instructions.isEmpty ? nil : instructions,
                            startDate: ISO8601DateFormatter().string(from: startDate),
                            endDate: hasEndDate ? ISO8601DateFormatter().string(from: endDate ?? Date()) : nil
                        )
                        onSave(medication)
                        dismiss()
                    }
                    .disabled(name.isEmpty || dosage.isEmpty || frequency.isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    MedicationsView()
        .environmentObject(NavigationManager())
}
