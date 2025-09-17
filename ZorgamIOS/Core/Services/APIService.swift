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
        return performGetRequest<HealthAssessmentResponse>(endpoint: "/assessments/\(type.rawValue.lowercased())")
    }
    
    func submitAssessment(type: AssessmentType, answers: [String: String]) -> AnyPublisher<AssessmentResult, APIError> {
        let request = AssessmentSubmissionRequest(answers: answers, type: type.rawValue)
        return performRequest(endpoint: "/assessments/submit", method: "POST", body: request)
    }
    
    // MARK: - Medications
    func getMedications() -> AnyPublisher<[Medication], APIError> {
        return performGetRequest<[Medication]>(endpoint: "/medications")
    }
    
    func addMedication(_ medication: AddMedicationRequest) -> AnyPublisher<MedicationResponse, APIError> {
        return performRequest(endpoint: "/medications", method: "POST", body: medication)
    }
    
    func updateMedication(id: Int, medication: AddMedicationRequest) -> AnyPublisher<MedicationResponse, APIError> {
        return performRequest(endpoint: "/medications/\(id)", method: "PUT", body: medication)
    }
    
    func deleteMedication(id: Int) -> AnyPublisher<APIResponse, APIError> {
        return performDeleteRequest<APIResponse>(endpoint: "/medications/\(id)")
    }
    
    // MARK: - Health Summary
    func getHealthSummary() -> AnyPublisher<HealthSummary, APIError> {
        print("🌐 Making API call to: \(baseURL)/dashboard/health-summary")
        return performGetRequest<HealthSummary>(endpoint: "/dashboard/health-summary")
    }
    
    func getWeatherData() -> AnyPublisher<WeatherData, APIError> {
        return performGetRequest<WeatherData>(endpoint: "/weather")
    }
    
    // MARK: - Questionnaires
    func getQuestionnaire(type: AssessmentType) -> AnyPublisher<[Questionnaire], APIError> {
        print("🌐 Making API call to: \(baseURL)/questionnaires/comprehensive/checkin/\(type.rawValue.lowercased())")
        return performGetRequest<[Questionnaire]>(endpoint: "/questionnaires/comprehensive/checkin/\(type.rawValue.lowercased())")
    }
    
    func submitQuestionnaire(submission: QuestionnaireSubmission) -> AnyPublisher<SubmissionResponse, APIError> {
        print("🌐 Making API call to: \(baseURL)/questionnaires/submissions")
        print("📤 Submission data: \(submission)")
        return performRequest<QuestionnaireSubmission, SubmissionResponse>(endpoint: "/questionnaires/submissions", method: "POST", body: submission)
    }
    
    // MARK: - Debug Method
    func debugSubmitQuestionnaire(submission: QuestionnaireSubmission) -> AnyPublisher<String, APIError> {
        print("🌐 Making DEBUG API call to: \(baseURL)/questionnaires/submissions")
        print("📤 Submission data: \(submission)")
        
        guard let url = URL(string: baseURL + "/questionnaires/submissions") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth token if available
        if let token = SessionManager().authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            request.httpBody = try JSONEncoder().encode(submission)
        } catch {
            return Fail(error: APIError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> String in
                print("📡 DEBUG API Response received")
                if let httpResponse = response as? HTTPURLResponse {
                    print("📊 HTTP Status Code: \(httpResponse.statusCode)")
                }
                print("📦 Response data size: \(data.count) bytes")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Raw response content: \(responseString)")
                    return responseString
                }
                return "No response content"
            }
            .mapError { error in
                print("❌ DEBUG Request error: \(error)")
                return APIError.networkError(error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Generic Request Methods
    private func performGetRequest<R: Codable>(endpoint: String) -> AnyPublisher<R, APIError> {
        guard let url = URL(string: baseURL + endpoint) else {
            print("❌ Invalid URL: \(baseURL + endpoint)")
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth token if available
        if let token = SessionManager().authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔑 Using auth token for request")
        } else {
            print("⚠️ No auth token available")
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                print("📡 API Response received for endpoint: \(endpoint)")
                // Check HTTP status code
                if let httpResponse = response as? HTTPURLResponse {
                    print("📊 HTTP Status Code: \(httpResponse.statusCode)")
                    switch httpResponse.statusCode {
                    case 200...299:
                        print("✅ API call successful")
                        break // Success
                    case 401:
                        print("❌ Unauthorized - Invalid credentials")
                        throw APIError.serverError("Invalid username or password")
                    case 400:
                        print("❌ Bad Request - Invalid request format")
                        throw APIError.serverError("Invalid request format")
                    case 500:
                        print("❌ Server Error")
                        throw APIError.serverError("Server error. Please try again later")
                    default:
                        print("❌ Request failed with status: \(httpResponse.statusCode)")
                        throw APIError.serverError("Request failed: \(httpResponse.statusCode)")
                    }
                }
                print("📦 Response data size: \(data.count) bytes")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Response content: \(responseString)")
                }
                return data
            }
            .decode(type: R.self, decoder: JSONDecoder())
            .mapError { error in
                print("❌ Decoding error: \(error)")
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
    
    private func performDeleteRequest<R: Codable>(endpoint: String) -> AnyPublisher<R, APIError> {
        guard let url = URL(string: baseURL + endpoint) else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth token if available
        if let token = SessionManager().authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
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
                        throw APIError.serverError("Request failed: \(httpResponse.statusCode)")
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
                print("📡 API Response received for endpoint: \(endpoint)")
                // Check HTTP status code
                if let httpResponse = response as? HTTPURLResponse {
                    print("📊 HTTP Status Code: \(httpResponse.statusCode)")
                    switch httpResponse.statusCode {
                    case 200...299:
                        print("✅ API call successful")
                        break // Success
                    case 401:
                        print("❌ Unauthorized - Invalid credentials")
                        throw APIError.serverError("Invalid username or password")
                    case 400:
                        print("❌ Bad Request - Invalid request format")
                        throw APIError.serverError("Invalid request format")
                    case 500:
                        print("❌ Server Error")
                        throw APIError.serverError("Server error. Please try again later")
                    default:
                        print("❌ Request failed with status: \(httpResponse.statusCode)")
                        throw APIError.serverError("Request failed: \(httpResponse.statusCode)")
                    }
                }
                print("📦 Response data size: \(data.count) bytes")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Response content: \(responseString)")
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
