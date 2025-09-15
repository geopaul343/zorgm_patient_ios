import Foundation

// MARK: - Medication Models
struct Medication: Codable, Identifiable {
    let id: Int
    let name: String
    let dosage: String
    let frequency: String
    let instructions: String?
    let startDate: String
    let endDate: String?
    let isActive: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case dosage
        case frequency
        case instructions
        case startDate = "start_date"
        case endDate = "end_date"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct AddMedicationRequest: Codable {
    let name: String
    let dosage: String
    let frequency: String
    let instructions: String?
    let startDate: String
    let endDate: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case dosage
        case frequency
        case instructions
        case startDate = "start_date"
        case endDate = "end_date"
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
