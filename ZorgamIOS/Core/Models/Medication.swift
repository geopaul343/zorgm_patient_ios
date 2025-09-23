import Foundation

// MARK: - Medication Models
struct Medication: Codable, Identifiable {
    let id: Int
    let name: String
    let dosage: String
    let frequency: String
    let color: String?
    let medicationType: String?
    let active: Bool?
    let userId: Int
    let lastTakenAt: String?
    let createdAt: String
    let updatedAt: String
    
    // Computed properties for UI compatibility
    var instructions: String? {
        return nil // API doesn't provide instructions
    }
    
    var startDate: String {
        return createdAt // Use created_at as start date
    }
    
    var endDate: String? {
        return nil // API doesn't provide end date
    }
    
    var isActive: Bool {
        return active ?? true // Use the actual active field, default to true if nil
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case dosage
        case frequency
        case color
        case medicationType = "medication_type"
        case active
        case userId = "user_id"
        case lastTakenAt = "last_taken_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct AddMedicationRequest: Codable {
    let name: String
    let dosage: String
    let frequency: String // Maps to reminder times - Format: "HH:mm,HH:mm" or frequency description
    let color: String // Hex color code
    let medicationType: String // pills, inhaler, nebulizer, injection, liquid, cream, other
    let active: Bool
    
    enum CodingKeys: String, CodingKey {
        case name
        case dosage
        case frequency
        case color
        case medicationType = "medication_type"
        case active
    }
    
    init(name: String, dosage: String, frequency: String, color: String = "#3B82F6", medicationType: String = "pills", active: Bool = true) {
        self.name = name
        self.dosage = dosage
        self.frequency = frequency
        self.color = color
        self.medicationType = medicationType
        self.active = active
    }
}

struct MedicationResponse: Codable {
    let success: Bool
    let message: String
    let medication: Medication?
}

// MARK: - Medication UI State
struct MedicationUIState {
    var medications: [Medication] = []
    var isLoading: Bool = false
    var isAdding: Bool = false
    var error: String? = nil
    var successMessage: String? = nil
}

// MARK: - Medication Result
enum MedicationResult {
    case success(Medication)
    case failure(String)
    case loading
}
