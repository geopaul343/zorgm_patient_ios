import SwiftUI

// MARK: - Medications View
struct MedicationsView: View {
    // MARK: - Environment Objects
    @EnvironmentObject private var navigationManager: NavigationManager
    
    // MARK: - State
    @StateObject private var viewModel = MedicationsViewModel()
    @State private var showingAddMedication = false
    @State private var showingEditMedication = false
    @State private var medicationToEdit: Medication?
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Synced Successfully Header
                if !viewModel.isLoading && !viewModel.medications.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Synced Successfully")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading medications...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.medications.isEmpty {
                    EmptyMedicationsView {
                        showingAddMedication = true
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(Array(viewModel.medications.enumerated()), id: \.element.id) { index, medication in
                                MedicationCard(
                                    medication: medication,
                                    colorIndex: index,
                                    onToggle: { isActive in
                                        // Handle toggle with notification management
                                        viewModel.toggleMedicationReminder(for: medication, isEnabled: isActive)
                                        print("Toggled medication \(medication.name) to \(isActive)")
                                    },
                                    onEdit: { medication in
                                        print("✏️ Edit button tapped for medication: \(medication.name)")
                                        // Set both values together to avoid timing issues
                                        medicationToEdit = medication
                                        showingEditMedication = true
                                        print("📱 showingEditMedication set to: \(showingEditMedication)")
                                        print("📱 medicationToEdit set to: \(medicationToEdit?.name ?? "nil")")
                                        
                                        // Verify the state is set correctly
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            print("🔍 After 0.1s - medicationToEdit: \(medicationToEdit?.name ?? "nil")")
                                        }
                                    },
                                    onDelete: { medication in
                                        // Handle delete
                                        viewModel.deleteMedication(medication)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .overlay(
                // Only show + button when there are medications
                Group {
                    if !viewModel.medications.isEmpty {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button(action: {
                                    showingAddMedication = true
                                }) {
                                    Image(systemName: "plus")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(width: 56, height: 56)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                }
                                .padding(.trailing, 20)
                                .padding(.bottom, 20)
                            }
                        }
                    }
                }
            )
            .navigationTitle("Medications")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddMedication) {
                AddMedicationView { medication in
                    viewModel.addMedication(medication)
                    // Schedule notification for new medication (assuming it's active by default)
                    if let newMedication = viewModel.medications.last {
                        viewModel.toggleMedicationReminder(for: newMedication, isEnabled: true)
                    }
                }
            }
            .sheet(isPresented: $showingEditMedication) {
                Group {
                    if let medication = medicationToEdit {
                        AddMedicationView(onSave: { request in
                            viewModel.updateMedication(medication, with: request)
                            // Update notification with new time
                            viewModel.updateMedicationReminder(for: medication)
                        }, medication: medication)
                        .onAppear {
                            print("✅ Edit sheet opened with medication: \(medication.name)")
                        }
                    } else {
                        // Fallback view if medication is nil
                        VStack {
                            Text("Loading medication data...")
                                .font(.headline)
                                .padding()
                            
                            Button("Retry") {
                                // Try to reload the medication data
                                Task {
                                    await viewModel.loadMedications()
                                }
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .onAppear {
                            print("⚠️ Edit sheet opened but medicationToEdit is nil")
                            print("⚠️ Current medicationToEdit value: \(medicationToEdit?.name ?? "nil")")
                            print("⚠️ Available medications: \(viewModel.medications.map { $0.name })")
                        }
                    }
                }
                .onAppear {
                    print("🔍 Sheet onAppear - medicationToEdit: \(medicationToEdit?.name ?? "nil")")
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
            print("💊 MedicationsView appeared - loading medications...")
            // Initialize notifications
            viewModel.initializeNotifications()
            
            Task {
                await viewModel.loadMedications()
                print("💊 MedicationsView - loadMedications completed")
            }
        }
        .onChange(of: showingEditMedication) { newValue in
            print("🔄 showingEditMedication changed to: \(newValue)")
            if newValue {
                print("🔄 Sheet is showing, medicationToEdit: \(medicationToEdit?.name ?? "nil")")
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
    let colorIndex: Int
    let onToggle: (Bool) -> Void
    let onEdit: (Medication) -> Void
    let onDelete: (Medication) -> Void
    
    @State private var isActive: Bool
    @State private var showingDeleteAlert = false
    
    // Color palette for the vertical bars (fallback)
    private let colors: [Color] = [.blue, .green, .orange, .purple, .red, .teal, .indigo, .pink]
    
    // Convert hex color to SwiftUI Color
    private func colorFromHex(_ hexString: String?) -> Color {
        guard let hexString = hexString else { return colors[colorIndex % colors.count] }
        
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return colors[colorIndex % colors.count]
        }
        
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    init(medication: Medication, colorIndex: Int, onToggle: @escaping (Bool) -> Void, onEdit: @escaping (Medication) -> Void, onDelete: @escaping (Medication) -> Void) {
        self.medication = medication
        self.colorIndex = colorIndex
        self.onToggle = onToggle
        self.onEdit = onEdit
        self.onDelete = onDelete
        self._isActive = State(initialValue: medication.isActive)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Colored vertical bar
            Rectangle()
                .fill(colorFromHex(medication.color))
                .frame(width: 4)
                .cornerRadius(2)
            
            // Main content
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(medication.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(medication.dosage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Medication Type
                    if let medicationType = medication.medicationType {
                        Text(medicationType.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
            }
            
            HStack {
                        Image(systemName: "clock")
                            .font(.caption)
                        .foregroundColor(.secondary)
                        Text(formatSchedule(medication.frequency))
                        .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Edit and Delete buttons near reminder time
                        HStack(spacing: 8) {
                            // Edit button
                            Button(action: {
                                onEdit(medication)
                            }) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.blue)
                                    .frame(width: 20, height: 20)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            
                            // Delete button
                            Button(action: {
                                showingDeleteAlert = true
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.red)
                                    .frame(width: 20, height: 20)
                                    .background(Color.red.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Toggle switch
                Toggle("", isOn: $isActive)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .onChange(of: isActive) { _, newValue in
                        onToggle(newValue)
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        .alert("Delete Medication", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete(medication)
            }
        } message: {
            Text("Are you sure you want to delete \(medication.name)? This action cannot be undone.")
        }
    }
    
    private func formatSchedule(_ frequency: String) -> String {
        // Convert frequency to a more readable schedule format
        // This is a simple implementation - you might want to make it more sophisticated
        switch frequency.lowercased() {
        case "daily":
            return "8:00 AM, 8:00 PM"
        case "twice daily":
            return "8:00 AM, 8:00 PM"
        case "once daily":
            return "8:00 AM"
        case "weekly":
            return "10:00 AM"
        case "as needed":
            return "As needed"
        default:
            return frequency
        }
    }
}

// MARK: - Add Medication View
struct AddMedicationView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onSave: (AddMedicationRequest) -> Void
    let medication: Medication?
    
    @State private var name = ""
    @State private var dosage = ""
    @State private var selectedMedicationType = "pills"
    @State private var selectedColor = "Blue"
    @State private var reminderTime = Date()
    @State private var showingTimePicker = false
    
    init(onSave: @escaping (AddMedicationRequest) -> Void, medication: Medication? = nil) {
        self.onSave = onSave
        self.medication = medication
    }
    
    private let medicationTypes = ["pills", "inhaler", "nebulizer", "injection", "liquid", "cream", "other"]
    private let medicationColors = [
        ("Blue", Color.blue),
        ("Green", Color.green),
        ("Orange", Color.orange),
        ("Primary", Color.blue),
        ("Gray", Color.gray)
    ]
    
    private func getHexColor(for colorName: String) -> String {
        switch colorName {
        case "Blue":
            return "#3B82F6"
        case "Green":
            return "#10B981"
        case "Orange":
            return "#F59E0B"
        case "Primary":
            return "#3B82F6"
        case "Gray":
            return "#6B7280"
        default:
            return "#3B82F6"
        }
    }
    
    private func getColorName(for hexColor: String) -> String {
        switch hexColor {
        case "#3B82F6":
            return "Blue"
        case "#10B981":
            return "Green"
        case "#F59E0B":
            return "Orange"
        case "#6B7280":
            return "Gray"
        default:
            return "Blue"
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Text(medication != nil ? "Edit Medication" : "Add Medication")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Invisible button for balance
                    Button(action: {}) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .opacity(0)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Medication Name
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Medication Name")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("*")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            
                            TextField("e.g., Metformin, Insulin", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.body)
                        }
                        
                        // Dosage
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Dosage")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("*")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            
                            TextField("e.g., 500mg, 2 tablets", text: $dosage)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.body)
                        }
                        
                        // Medication Type
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Medication Type")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("*")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                                ForEach(medicationTypes, id: \.self) { type in
                                    Button(action: {
                                        selectedMedicationType = type
                                    }) {
                                        Text(type.capitalized)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(selectedMedicationType == type ? .white : .primary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(selectedMedicationType == type ? Color.blue : Color.clear)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                                    )
                                            )
                                    }
                                }
                            }
                        }
                        
                        // Medication Color
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Medication Color")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("*")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            
                            HStack(spacing: 16) {
                                ForEach(medicationColors, id: \.0) { colorName, color in
                                    VStack(spacing: 6) {
                                        Button(action: {
                                            selectedColor = colorName
                                        }) {
                                            Circle()
                                                .fill(color)
                                                .frame(width: 50, height: 50)
                                                .overlay(
                                                    Circle()
                                                        .stroke(selectedColor == colorName ? Color.blue : Color.clear, lineWidth: 3)
                                                )
                                        }
                                        
                                        Text(colorName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Reminder Time
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Reminder Time")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("*")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            
                            Button(action: {
                                showingTimePicker = true
                            }) {
                                HStack {
                                    Text(formatTime(reminderTime))
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray6))
                                )
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                // Add Medication Button
                VStack {
                    Button(action: {
                        let medication = AddMedicationRequest(
                            name: name,
                            dosage: dosage,
                            frequency: formatTime(reminderTime),
                            color: getHexColor(for: selectedColor),
                            medicationType: selectedMedicationType,
                            active: true
                        )
                        onSave(medication)
                        dismiss()
                    }) {
                        Text(medication != nil ? "Update Medication" : "Add Medication")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(isFormValid ? .white : .gray)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isFormValid ? Color.blue : Color.gray.opacity(0.3))
                            )
                    }
                    .disabled(!isFormValid)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingTimePicker) {
            TimePickerView(selectedTime: $reminderTime)
        }
        .onAppear {
            print("🔧 AddMedicationView onAppear called")
            print("🔧 Medication parameter: \(medication?.name ?? "nil")")
            
            if let medication = medication {
                print("🔧 Edit Mode: Pre-filling form with medication data")
                print("📝 Name: \(medication.name)")
                print("💊 Dosage: \(medication.dosage)")
                print("⏰ Frequency: \(medication.frequency)")
                print("🎨 Color: \(medication.color ?? "nil")")
                print("💊 Type: \(medication.medicationType ?? "nil")")
                
                name = medication.name
                dosage = medication.dosage
                
                // Set medication type
                if let medicationType = medication.medicationType {
                    selectedMedicationType = medicationType
                }
                
                // Set color
                if let color = medication.color {
                    selectedColor = getColorName(for: color)
                }
                
                // Parse the frequency to set the reminder time
                if let time = parseTimeFromFrequency(medication.frequency) {
                    print("✅ Successfully parsed time: \(time)")
                    reminderTime = time
                } else {
                    print("⚠️ Could not parse time from frequency: \(medication.frequency)")
                    // Set a default time if parsing fails
                    reminderTime = Date()
                }
            } else {
                print("➕ Add Mode: Starting with empty form")
                print("⚠️ No medication provided for editing")
            }
        }
    }
    
    private var isFormValid: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !dosage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !selectedMedicationType.isEmpty &&
               !selectedColor.isEmpty
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func parseTimeFromFrequency(_ frequency: String) -> Date? {
        print("🕐 Attempting to parse frequency: '\(frequency)'")
        
        // Try different time formats
        let formatters = [
            // Short time format (e.g., "8:00 AM", "20:00")
            { () -> DateFormatter in
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return formatter
            }(),
            // 24-hour format (e.g., "20:00")
            { () -> DateFormatter in
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                return formatter
            }(),
            // 12-hour format with AM/PM (e.g., "8:00 AM")
            { () -> DateFormatter in
                let formatter = DateFormatter()
                formatter.dateFormat = "h:mm a"
                return formatter
            }(),
            // 12-hour format without AM/PM (e.g., "8:00")
            { () -> DateFormatter in
                let formatter = DateFormatter()
                formatter.dateFormat = "h:mm"
                return formatter
            }()
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: frequency) {
                print("✅ Successfully parsed with format: \(formatter.dateFormat ?? "timeStyle")")
                return date
            }
        }
        
        print("❌ Could not parse frequency with any known format")
        return nil
    }
}

// MARK: - Time Picker View
struct TimePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTime: Date
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("Select Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(WheelDatePickerStyle())
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Reminder Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
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
