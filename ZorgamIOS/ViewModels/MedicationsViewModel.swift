import Foundation
import Combine

// MARK: - Medications View Model
class MedicationsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var medications: [Medication] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let apiService = APIService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    @MainActor
    func loadMedications() async {
        isLoading = true
        errorMessage = nil
        
        apiService.getMedications()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    self?.isLoading = false
                    if case .failure(let error) = result {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] medications in
                    self?.medications = medications
                }
            )
            .store(in: &cancellables)
    }
    
    @MainActor
    func addMedication(_ request: AddMedicationRequest) {
        apiService.addMedication(request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    if case .failure(let error) = result {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] response in
                    if response.success, let medication = response.medication {
                        self?.medications.append(medication)
                    } else {
                        self?.errorMessage = response.message
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    @MainActor
    func updateMedication(_ medication: Medication, with request: AddMedicationRequest) {
        apiService.updateMedication(id: medication.id, medication: request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    if case .failure(let error) = result {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] response in
                    if response.success, let updatedMedication = response.medication {
                        if let index = self?.medications.firstIndex(where: { $0.id == medication.id }) {
                            self?.medications[index] = updatedMedication
                        }
                    } else {
                        self?.errorMessage = response.message
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    @MainActor
    func deleteMedication(_ medication: Medication) {
        apiService.deleteMedication(id: medication.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    if case .failure(let error) = result {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] response in
                    if response.success {
                        self?.medications.removeAll { $0.id == medication.id }
                    } else {
                        self?.errorMessage = response.message
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func clearError() {
        errorMessage = nil
    }
}
