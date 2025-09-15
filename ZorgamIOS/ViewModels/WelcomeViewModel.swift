import Foundation
import Combine

// MARK: - Welcome View Model
class WelcomeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Computed Properties
    var isFormValid: Bool {
        !username.isEmpty && !password.isEmpty && username.count >= 3
    }
    
    // MARK: - Private Properties
    private let apiService = APIService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    func login(completion: @escaping (AuthResult) -> Void) {
        guard isFormValid else {
            errorMessage = "Please fill in all fields correctly"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Try the actual login
        performLogin(completion: completion)
    }
    
    private func performLogin(completion: @escaping (AuthResult) -> Void) {
        apiService.login(username: username, password: password)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    self?.isLoading = false
                    if case .failure(let error) = result {
                        self?.errorMessage = error.localizedDescription
                        completion(.failure(error.localizedDescription))
                    }
                },
                receiveValue: { [weak self] response in
                    self?.isLoading = false
                    completion(.success(response))
                }
            )
            .store(in: &cancellables)
    }
    
    func clearError() {
        errorMessage = nil
    }
}
