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
    
    // MARK: - Token Validation
    func isTokenValid() -> Bool {
        guard let token = authToken else { return false }
        
        // Decode JWT token to check expiry
        let parts = token.components(separatedBy: ".")
        guard parts.count == 3 else { return false }
        
        // Decode payload (second part)
        let payload = parts[1]
        let paddedPayload = payload.padding(toLength: ((payload.count + 3) / 4) * 4, withPad: "=", startingAt: 0)
        
        guard let data = Data(base64Encoded: paddedPayload),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let exp = json["exp"] as? TimeInterval else { return false }
        
        let currentTime = Date().timeIntervalSince1970
        let isExpired = currentTime >= exp
        
        if isExpired {
            print("⚠️ Token expired at: \(Date(timeIntervalSince1970: exp))")
            print("🕐 Current time: \(Date())")
        } else {
            print("✅ Token is valid until: \(Date(timeIntervalSince1970: exp))")
        }
        
        return !isExpired
    }
    
    func clearSession() {
        currentUser = nil
        authToken = nil
        isLoggedIn = false
        userDefaults.removeObject(forKey: authTokenKey)
        userDefaults.removeObject(forKey: userKey)
        print("🔓 Session cleared")
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
