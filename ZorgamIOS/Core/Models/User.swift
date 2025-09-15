import Foundation

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: Int
    let email: String
    let fullName: String
    let role: String
    let regionCode: String
    let diseaseId: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case role
        case regionCode = "region_code"
        case diseaseId = "disease_id"
    }
}

// MARK: - Authentication Models
struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct LoginResponse: Codable {
    let success: Bool
    let firebaseToken: String
    let user: User
    
    enum CodingKeys: String, CodingKey {
        case success
        case firebaseToken = "firebase_token"
        case user
    }
}

// MARK: - Authentication Result
enum AuthResult {
    case success(LoginResponse)
    case failure(String)
    case loading
}
