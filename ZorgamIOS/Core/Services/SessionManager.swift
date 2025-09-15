import Foundation
import Combine

// MARK: - Session Manager
class SessionManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?
    @Published var authToken: String?
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let authTokenKey = "auth_token"
    private let userKey = "current_user"
    
    // MARK: - Initialization
    init() {
        loadStoredSession()
    }
    
    // MARK: - Public Methods
    func initialize() {
        // Initialize any required services
        print("SessionManager initialized")
    }
    
    func login(user: User, token: String) {
        self.currentUser = user
        self.authToken = token
        self.isLoggedIn = true
        
        // Store session data
        storeSession(user: user, token: token)
    }
    
    func login(response: LoginResponse) {
        self.currentUser = response.user
        self.authToken = response.firebaseToken
        self.isLoggedIn = true
        
        // Store session data
        storeSession(user: response.user, token: response.firebaseToken)
    }
    
    func logout() {
        self.currentUser = nil
        self.authToken = nil
        self.isLoggedIn = false
        
        // Clear stored session data
        clearStoredSession()
    }
    
    func updateUser(_ user: User) {
        self.currentUser = user
        storeUser(user)
    }
    
    // MARK: - Private Methods
    private func loadStoredSession() {
        if let token = userDefaults.string(forKey: authTokenKey),
           let userData = userDefaults.data(forKey: userKey),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.authToken = token
            self.currentUser = user
            self.isLoggedIn = true
        }
    }
    
    private func storeSession(user: User, token: String) {
        userDefaults.set(token, forKey: authTokenKey)
        if let userData = try? JSONEncoder().encode(user) {
            userDefaults.set(userData, forKey: userKey)
        }
    }
    
    private func storeUser(_ user: User) {
        if let userData = try? JSONEncoder().encode(user) {
            userDefaults.set(userData, forKey: userKey)
        }
    }
    
    private func clearStoredSession() {
        userDefaults.removeObject(forKey: authTokenKey)
        userDefaults.removeObject(forKey: userKey)
    }
}
