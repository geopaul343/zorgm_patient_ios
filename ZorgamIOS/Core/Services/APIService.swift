import Foundation
import Combine

// MARK: - API Service
class APIService: ObservableObject {
    // MARK: - Properties
    private let baseURL = "https://zorgm-api-q7ppsor5da-uc.a.run.app/api/v1"
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Authentication
    func login(username: String, password: String) -> AnyPublisher<LoginResponse, APIError> {
        let request = LoginRequest(username: username, password: password)
        return performRequest(endpoint: "/auth/patient/login", method: "POST", body: request)
    }
    
    // MARK: - Health Assessments
    func getHealthAssessment(type: AssessmentType) -> AnyPublisher<HealthAssessmentResponse, APIError> {
        return performRequest(endpoint: "/assessments/\(type.rawValue.lowercased())", method: "GET", body: EmptyRequest())
    }
    
    func submitAssessment(type: AssessmentType, answers: [String: String]) -> AnyPublisher<AssessmentResult, APIError> {
        let request = AssessmentSubmissionRequest(answers: answers, type: type.rawValue)
        return performRequest(endpoint: "/assessments/submit", method: "POST", body: request)
    }
    
    // MARK: - Medications
    func getMedications() -> AnyPublisher<[Medication], APIError> {
        return performRequest(endpoint: "/medications", method: "GET", body: EmptyRequest())
    }
    
    func addMedication(_ medication: AddMedicationRequest) -> AnyPublisher<MedicationResponse, APIError> {
        return performRequest(endpoint: "/medications", method: "POST", body: medication)
    }
    
    func updateMedication(id: Int, medication: AddMedicationRequest) -> AnyPublisher<MedicationResponse, APIError> {
        return performRequest(endpoint: "/medications/\(id)", method: "PUT", body: medication)
    }
    
    func deleteMedication(id: Int) -> AnyPublisher<APIResponse, APIError> {
        return performRequest(endpoint: "/medications/\(id)", method: "DELETE", body: EmptyRequest())
    }
    
    // MARK: - Health Summary
    func getHealthSummary() -> AnyPublisher<HealthSummary, APIError> {
        return performRequest(endpoint: "/health/summary", method: "GET")
    }
    
    func getWeatherData() -> AnyPublisher<WeatherData, APIError> {
        return performRequest(endpoint: "/weather", method: "GET")
    }
    
    // MARK: - Generic Request Method
    private func performRequest<T: Codable, R: Codable>(
        endpoint: String,
        method: String,
        body: T? = nil
    ) -> AnyPublisher<R, APIError> {
        guard let url = URL(string: baseURL + endpoint) else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth token if available
        if let token = SessionManager().authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                return Fail(error: APIError.encodingError)
                    .eraseToAnyPublisher()
            }
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                // Check HTTP status code
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200...299:
                        break // Success
                    case 401:
                        throw APIError.serverError("Invalid username or password")
                    case 400:
                        throw APIError.serverError("Invalid request format")
                    case 500:
                        throw APIError.serverError("Server error. Please try again later")
                    default:
                        throw APIError.serverError("Login failed: \(httpResponse.statusCode)")
                    }
                }
                return data
            }
            .decode(type: R.self, decoder: JSONDecoder())
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                } else if error is DecodingError {
                    return APIError.decodingError
                } else {
                    return APIError.networkError(error.localizedDescription)
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - API Error
enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(String)
    case decodingError
    case encodingError
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let message):
            return "Network Error: \(message)"
        case .decodingError:
            return "Failed to decode response"
        case .encodingError:
            return "Failed to encode request"
        case .serverError(let message):
            return message
        }
    }
}

// MARK: - Generic API Response
struct APIResponse: Codable {
    let success: Bool
    let message: String
}

// MARK: - Error Response
struct ErrorResponse: Codable {
    let detail: String
    let message: String?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case detail
        case message
        case error
    }
}

// MARK: - Empty Request Type
struct EmptyRequest: Codable {}

// MARK: - Assessment Submission Request
struct AssessmentSubmissionRequest: Codable {
    let answers: [String: String]
    let type: String
}
