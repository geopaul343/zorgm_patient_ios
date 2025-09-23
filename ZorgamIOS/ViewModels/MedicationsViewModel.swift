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
    private let notificationService = NotificationService.shared
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
                    print("✅ Successfully loaded \(medications.count) medications from API")
                }
            )
            .store(in: &cancellables)
    }
    
    @MainActor
    func addMedication(_ request: AddMedicationRequest) {
        // API call
        apiService.addMedication(request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    if case .failure(let error) = result {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] medication in
                    self?.medications.append(medication)
                    self?.errorMessage = nil // Clear any previous error
                    // Refresh the medications list to ensure we have the latest data
                    Task {
                        await self?.loadMedications()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    @MainActor
    func updateMedication(_ medication: Medication, with request: AddMedicationRequest) {
        // API call
        apiService.updateMedication(id: medication.id, medication: request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    if case .failure(let error) = result {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] updatedMedication in
                    if let index = self?.medications.firstIndex(where: { $0.id == medication.id }) {
                        self?.medications[index] = updatedMedication
                    }
                    self?.errorMessage = nil // Clear any previous error
                }
            )
            .store(in: &cancellables)
    }
    
    @MainActor
    func deleteMedication(_ medication: Medication) {
        // API call
        apiService.deleteMedication(id: medication.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    if case .failure(let error) = result {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.medications.removeAll { $0.id == medication.id }
                    self?.errorMessage = nil // Clear any previous error
                }
            )
            .store(in: &cancellables)
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Notification Management
    func toggleMedicationReminder(for medication: Medication, isEnabled: Bool) {
        if isEnabled {
            // Schedule notification
            notificationService.scheduleMedicationReminder(for: medication)
            print("🔔 Enabled reminder for \(medication.name)")
        } else {
            // Cancel notification
            notificationService.cancelMedicationReminder(for: medication)
            print("🔕 Disabled reminder for \(medication.name)")
        }
    }
    
    func updateMedicationReminder(for medication: Medication) {
        // Update the notification with new time
        notificationService.updateMedicationReminder(for: medication)
        print("🔄 Updated reminder for \(medication.name)")
    }
    
    func cancelAllReminders() {
        notificationService.cancelAllMedicationReminders()
        print("🔕 Cancelled all medication reminders")
    }
    
    // MARK: - Initialize Notifications
    func initializeNotifications() {
        Task {
            let permissionGranted = await notificationService.requestNotificationPermission()
            if permissionGranted {
                print("✅ Notification permission granted and categories set up")
                // Check notification settings for debugging
                await notificationService.checkNotificationSettings()
            } else {
                print("❌ Notification permission denied")
            }
        }
    }
    
    // MARK: - Test Notification
    func testNotification(for medication: Medication) {
        print("🧪 Testing notification for \(medication.name)")
        notificationService.testNotification(for: medication)
    }
    
    // MARK: - Force Immediate Notification
    func forceImmediateNotification(for medication: Medication) {
        print("🚨 Force immediate notification for \(medication.name)")
        notificationService.forceImmediateNotification(for: medication)
    }
    
    // MARK: - Test Sound Directly
    func testSoundDirectly() {
        print("🔊 Testing sound directly...")
        notificationService.testSoundDirectly()
    }
    
    // MARK: - Test Alarm Sound
    func testAlarmSound() {
        print("🚨 Testing alarm sound...")
        notificationService.testAlarmSound()
    }
    
    // MARK: - Create Alarm Notification
    func createAlarmNotification(for medication: Medication) {
        print("🚨 Creating alarm notification for \(medication.name)")
        notificationService.createAlarmNotification(for: medication)
    }
    
    // MARK: - Test Background Notification
    func testBackgroundNotification(for medication: Medication) {
        print("🚨 Testing background notification for \(medication.name)")
        notificationService.testBackgroundNotification(for: medication)
    }
    
    // MARK: - Create Alarm Sound File
    func createAlarmSoundFile() {
        print("🎵 Creating alarm sound file...")
        notificationService.createAlarmSoundFile()
    }
    
    // MARK: - Request Background App Refresh
    func requestBackgroundAppRefresh() {
        print("🔄 Requesting background app refresh...")
        notificationService.requestBackgroundAppRefresh()
    }
    
    // MARK: - Check Notification Settings
    func checkNotificationSettings() async {
        await notificationService.checkNotificationSettings()
    }
    
}
