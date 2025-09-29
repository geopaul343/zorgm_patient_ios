import Foundation
import Combine

// MARK: - API Service
class APIService: ObservableObject {
    // MARK: - Properties
    private let baseURL = "https://zorgm-new-api-887192895309.us-central1.run.app/api/v1"
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Authentication
    func login(username: String, password: String) -> AnyPublisher<LoginResponse, APIError> {
        print("🔐 Starting Login API call...")
        print("📡 Endpoint: /auth/patient/login")
        print("👤 Username: \(username)")
        print("🔑 Password: [HIDDEN]")
        
        let url = baseURL + "/auth/patient/login"
        print("🌐 Full URL: \(url)")
        
        // Create custom URLSession with HTTP/3 configuration
        let config = URLSessionConfiguration.ephemeral
        config.httpMaximumConnectionsPerHost = 6 // HTTP/3 supports multiple streams
        config.httpShouldUsePipelining = true // HTTP/3 supports multiplexing
        config.allowsCellularAccess = true
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        // Enable HTTP/3 and modern protocols
        if #available(iOS 15.0, *) {
            config.allowsConstrainedNetworkAccess = true
            config.allowsExpensiveNetworkAccess = true
        }
        
        config.httpAdditionalHeaders = [
            "User-Agent": "ZorgamIOS/1.0 (iOS; HTTP/3)"
        ]
        let customSession = URLSession(configuration: config)
        
        // Create URLRequest with proper headers
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.timeoutInterval = 30.0
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // HTTP/3 doesn't need Connection headers - handled by QUIC protocol
        
        // No authentication token needed for login
        print("⚠️ No authentication token available")
        
        // Encode the login request body
        let loginRequest = LoginRequest(username: username, password: password)
        do {
            let jsonData = try JSONEncoder().encode(loginRequest)
            request.httpBody = jsonData
            print("📤 Request Body: \(String(data: jsonData, encoding: .utf8) ?? "Failed to encode")")
        } catch {
            print("❌ Failed to encode login request: \(error)")
            return Fail(error: APIError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return customSession.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                // Log response size and status
                let dataSize = data.count
                print("📊 Response size: \(dataSize) bytes (\(String(format: "%.2f", Double(dataSize) / 1024.0)) KB)")
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 HTTP Status Code: \(httpResponse.statusCode)")
                    print("📡 HTTP Version: \(httpResponse.value(forHTTPHeaderField: "HTTP-Version") ?? "Unknown")")
                    print("📡 Response Headers: \(httpResponse.allHeaderFields)")
                    
                    if httpResponse.statusCode >= 400 {
                        throw APIError.serverError("Server returned status code: \(httpResponse.statusCode)")
                    }
                }
                
                // Log raw response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🔍 Raw API Response:")
                    print("=====================================")
                    print(responseString)
                    print("=====================================")
                } else {
                    print("❌ Could not convert response data to string")
                    // Log first 100 bytes as hex for debugging
                    let hexString = data.prefix(100).map { String(format: "%02x", $0) }.joined(separator: " ")
                    print("🔍 First 100 bytes (hex): \(hexString)")
                }
                
                return data
            }
            .decode(type: LoginResponse.self, decoder: JSONDecoder())
            .mapError { error in
                if error is DecodingError {
                    print("❌ Decoding Error Details: \(error)")
                    return APIError.decodingError
                } else if let apiError = error as? APIError {
                    return apiError
                } else {
                    return APIError.networkError(error.localizedDescription)
                }
            }
            .retry(2)
            .receive(on: DispatchQueue.main)
            .handleEvents(
                receiveOutput: { response in
                    print("✅ Login API Response received:")
                    print("🔍 Raw Login Response:")
                    print("=====================================")
                    print("📊 Success: \(response.success)")
                    print("🔥 Firebase Token: \(response.firebaseToken)")
                    print("👤 User Details:")
                    print("   🆔 ID: \(response.user.id)")
                    print("   📧 Email: \(response.user.email)")
                    print("   👤 Full Name: \(response.user.fullName)")
                    print("   🎭 Role: \(response.user.role)")
                    print("   🌍 Region Code: \(response.user.regionCode)")
                    print("   🏥 Disease ID: \(response.user.diseaseId)")
                    print("=====================================")
                },
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("✅ Login API call completed successfully")
                    case .failure(let error):
                        print("❌ Login API Error: \(error.localizedDescription)")
                    }
                }
            )
            .eraseToAnyPublisher()
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
        print("💊 Starting getMedications API call...")
        print("📡 Endpoint: /medications/")
        
        // Try using the EXACT same approach as getSubmissions with full URL
        let urlString = baseURL + "/medications/"
        print("🌐 Full URL: \(urlString)")
        print("🌐 URL Components:")
        if let urlComponents = URLComponents(string: urlString) {
            print("   Scheme: \(urlComponents.scheme ?? "nil")")
            print("   Host: \(urlComponents.host ?? "nil")")
            print("   Path: \(urlComponents.path)")
            print("   Query: \(urlComponents.query ?? "nil")")
        }
        
        guard let requestURL = URL(string: urlString) else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: requestURL, timeoutInterval: Double.infinity)
        request.httpMethod = "GET"
        // Remove ALL extra headers - match Postman exactly
        // request.cachePolicy = .reloadIgnoringLocalCacheData  // ❌ Postman doesn't set this
        // request.setValue("application/json", forHTTPHeaderField: "Accept")  // ❌ Postman doesn't send this
        
        // Match Postman/curl exactly - minimal headers
        if let token = SessionManager().authToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔐 Using Firebase token for authentication: \(String(token.prefix(20)))...")
            print("🔐 Full token length: \(token.count) characters")
            print("🔐 Token starts with: \(String(token.prefix(50)))...")
            print("🔐 Token ends with: ...\(String(token.suffix(50)))")
        } else {
            print("⚠️ No Firebase token available - request will be sent without authentication")
        }
        
        // Log ALL request headers to compare with Postman/curl
        print("📋 Request Headers Being Sent:")
        if let allHeaders = request.allHTTPHeaderFields {
            for (key, value) in allHeaders {
                print("   \(key): \(value)")
            }
        } else {
            print("   No headers found")
        }
        
        // Remove problematic headers that Postman/curl don't send
        // request.setValue("application/json", forHTTPHeaderField: "Content-Type") // ❌ Wrong for GET
        // HTTP/3 doesn't need Connection headers - handled by QUIC protocol
        // request.setValue("close", forHTTPHeaderField: "Connection") // ❌ Confusing
        
        // Create custom URLSession optimized for HTTP/3
        let config = URLSessionConfiguration.ephemeral
        config.httpMaximumConnectionsPerHost = 6 // HTTP/3 supports multiple streams
        config.httpShouldUsePipelining = true // HTTP/3 supports multiplexing
        config.allowsCellularAccess = true
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        // Enable modern protocols for HTTP/3
        if #available(iOS 15.0, *) {
            config.allowsConstrainedNetworkAccess = true
            config.allowsExpensiveNetworkAccess = true
        }
        
        // HTTP/3 headers - no Connection header needed
        // Enable HTTP/3 and modern protocols
        if #available(iOS 15.0, *) {
            config.allowsConstrainedNetworkAccess = true
            config.allowsExpensiveNetworkAccess = true
        }
        
        config.httpAdditionalHeaders = [
            "User-Agent": "ZorgamIOS/1.0 (iOS; HTTP/3)"
        ]
        
        let session = URLSession(configuration: config)
        
        return session.dataTaskPublisher(for: request)
            .retry(2) // Retry up to 2 times on failure
            .tryMap { data, response -> Data in
                // Log response size and status
                let dataSize = data.count
                print("📊 Response size: \(dataSize) bytes (\(String(format: "%.2f", Double(dataSize) / 1024.0)) KB)")
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 HTTP Status Code: \(httpResponse.statusCode)")
                    print("📡 HTTP Version: \(httpResponse.value(forHTTPHeaderField: "HTTP-Version") ?? "Unknown")")
                    print("📡 Response Headers: \(httpResponse.allHeaderFields)")
                    
                    // Log raw response for debugging BEFORE checking status code
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("🔍 Raw API Response:")
                        print("=====================================")
                        print(responseString)
                        print("=====================================")
                    } else {
                        print("❌ Could not convert response data to string")
                    }
                    
                    // Check HTTP status code AFTER logging
                    if httpResponse.statusCode >= 400 {
                        throw APIError.serverError("Server returned status code: \(httpResponse.statusCode)")
                    }
                }
                
                return data
            }
            .decode(type: [Medication].self, decoder: JSONDecoder())
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                } else if error is DecodingError {
                    print("❌ Decoding Error Details: \(error)")
                    return APIError.decodingError
                } else {
                    return APIError.networkError(error.localizedDescription)
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()

    }
    
    func addMedication(_ medication: AddMedicationRequest) -> AnyPublisher<Medication, APIError> {
        print("💊 Starting addMedication API call...")
        print("📡 Endpoint: /medications")
        
        // Use the correct base URL for medications API
//        let medicationsBaseURL = "https://zorgm-api-q7ppsor5da-uc.a.run.app/api/v1"
        let url = baseURL + "/medications/"
        print("🌐 Full URL: \(url)")
        
        // Add Firebase token from login response if available
        if let token = SessionManager().authToken {
            print("🔐 Using Firebase token for authentication: \(String(token.prefix(20)))...")
        } else {
            print("⚠️ No Firebase token available - request will be sent without authentication")
        }
        
        // Create custom URLSession with HTTP/3 configuration
        let config = URLSessionConfiguration.ephemeral
        config.httpMaximumConnectionsPerHost = 6 // HTTP/3 supports multiple streams
        config.httpShouldUsePipelining = true // HTTP/3 supports multiplexing
        config.allowsCellularAccess = true
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        // Enable HTTP/3 and modern protocols
        if #available(iOS 15.0, *) {
            config.allowsConstrainedNetworkAccess = true
            config.allowsExpensiveNetworkAccess = true
        }
        
        config.httpAdditionalHeaders = [
            "User-Agent": "ZorgamIOS/1.0 (iOS; HTTP/3)"
        ]
        let customSession = URLSession(configuration: config)
        
        // Create URLRequest with proper headers
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.timeoutInterval = 30.0
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // HTTP/3 doesn't need Connection headers - handled by QUIC protocol
        
        // Add Firebase token from login response if available
        if let token = SessionManager().authToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔐 Using Firebase token for authentication: \(String(token.prefix(20)))...")
        } else {
            print("⚠️ No Firebase token available - request will be sent without authentication")
        }
        
        // Encode the medication request body
        do {
            let jsonData = try JSONEncoder().encode(medication)
            request.httpBody = jsonData
            print("📤 Request Body: \(String(data: jsonData, encoding: .utf8) ?? "Failed to encode")")
        } catch {
            print("❌ Failed to encode medication request: \(error)")
            return Fail(error: APIError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return customSession.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                // Log response size and status
                let dataSize = data.count
                print("📊 Response size: \(dataSize) bytes (\(String(format: "%.2f", Double(dataSize) / 1024.0)) KB)")
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 HTTP Status Code: \(httpResponse.statusCode)")
                    print("📡 HTTP Version: \(httpResponse.value(forHTTPHeaderField: "HTTP-Version") ?? "Unknown")")
                    print("📡 Response Headers: \(httpResponse.allHeaderFields)")
                    
                    if httpResponse.statusCode >= 400 {
                        throw APIError.serverError("Server returned status code: \(httpResponse.statusCode)")
                    }
                }
                
                // Log raw response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🔍 Raw API Response:")
                    print("=====================================")
                    print(responseString)
                    print("=====================================")
                } else {
                    print("❌ Could not convert response data to string")
                    // Log first 100 bytes as hex for debugging
                    let hexString = data.prefix(100).map { String(format: "%02x", $0) }.joined(separator: " ")
                    print("🔍 First 100 bytes (hex): \(hexString)")
                }
                
                return data
            }
            .decode(type: Medication.self, decoder: JSONDecoder())
            .mapError { error in
                if error is DecodingError {
                    print("❌ Decoding Error Details: \(error)")
                    return APIError.decodingError
                } else if let apiError = error as? APIError {
                    return apiError
                } else {
                    return APIError.networkError(error.localizedDescription)
                }
            }
            .retry(2)
            .receive(on: DispatchQueue.main)
            .handleEvents(
                receiveOutput: { response in
                    print("✅ addMedication API Response received:")
                    print("💊 Medication Details:")
                    print("   🆔 ID: \(response.id)")
                    print("   💊 Name: \(response.name)")
                    print("   📏 Dosage: \(response.dosage)")
                    print("   ⏰ Frequency: \(response.frequency)")
                },
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("✅ addMedication API call completed successfully")
                    case .failure(let error):
                        print("❌ addMedication API Error: \(error)")
                    }
                }
            )
            .eraseToAnyPublisher()
    }
    
    func updateMedication(id: Int, medication: AddMedicationRequest) -> AnyPublisher<Medication, APIError> {
        print("💊 Starting updateMedication API call...")
        print("📡 Endpoint: /medications/\(id)/")
        
        let url = baseURL + "/medications/\(id)/"
        print("🌐 Full URL: \(url)")
        
        // Add Firebase token from login response if available
        if let token = SessionManager().authToken {
            print("🔐 Using Firebase token for authentication: \(String(token.prefix(20)))...")
        } else {
            print("⚠️ No Firebase token available - request will be sent without authentication")
        }
        
        // Create custom URLSession with HTTP/3 configuration
        let config = URLSessionConfiguration.ephemeral
        config.httpMaximumConnectionsPerHost = 6 // HTTP/3 supports multiple streams
        config.httpShouldUsePipelining = true // HTTP/3 supports multiplexing
        config.allowsCellularAccess = true
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        // Enable HTTP/3 and modern protocols
        if #available(iOS 15.0, *) {
            config.allowsConstrainedNetworkAccess = true
            config.allowsExpensiveNetworkAccess = true
        }
        
        config.httpAdditionalHeaders = [
            "User-Agent": "ZorgamIOS/1.0 (iOS; HTTP/3)"
        ]
        let customSession = URLSession(configuration: config)
        
        // Create URLRequest with proper headers
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "PUT"
        request.timeoutInterval = 30.0
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // HTTP/3 doesn't need Connection headers - handled by QUIC protocol
        
        // Add Firebase token from login response if available
        if let token = SessionManager().authToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔐 Using Firebase token for authentication: \(String(token.prefix(20)))...")
        } else {
            print("⚠️ No Firebase token available - request will be sent without authentication")
        }
        
        // Encode the medication request body
        do {
            let jsonData = try JSONEncoder().encode(medication)
            request.httpBody = jsonData
            print("📤 Request Body: \(String(data: jsonData, encoding: .utf8) ?? "Failed to encode")")
        } catch {
            print("❌ Failed to encode medication request: \(error)")
            return Fail(error: APIError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return customSession.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                // Log response size and status
                let dataSize = data.count
                print("📊 Response size: \(dataSize) bytes (\(String(format: "%.2f", Double(dataSize) / 1024.0)) KB)")
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 HTTP Status Code: \(httpResponse.statusCode)")
                    print("📡 HTTP Version: \(httpResponse.value(forHTTPHeaderField: "HTTP-Version") ?? "Unknown")")
                    print("📡 Response Headers: \(httpResponse.allHeaderFields)")
                    
                    if httpResponse.statusCode >= 400 {
                        throw APIError.serverError("Server returned status code: \(httpResponse.statusCode)")
                    }
                }
                
                // Log raw response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🔍 Raw API Response:")
                    print("=====================================")
                    print(responseString)
                    print("=====================================")
                } else {
                    print("❌ Could not convert response data to string")
                    // Log first 100 bytes as hex for debugging
                    let hexString = data.prefix(100).map { String(format: "%02x", $0) }.joined(separator: " ")
                    print("🔍 First 100 bytes (hex): \(hexString)")
                }
                
                return data
            }
            .retry(2)
            .receive(on: DispatchQueue.main)
            .decode(type: Medication.self, decoder: JSONDecoder())
            .handleEvents(
                receiveOutput: { response in
                    print("✅ updateMedication API Response received:")
                    print("💊 Medication Details:")
                    print("   🆔 ID: \(response.id)")
                    print("   💊 Name: \(response.name)")
                    print("   📏 Dosage: \(response.dosage)")
                    print("   ⏰ Frequency: \(response.frequency)")
                },
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("✅ updateMedication API call completed successfully")
                    case .failure(let error):
                        print("❌ updateMedication API Error: \(error)")
                    }
                }
            )
            .mapError { error in
                if error is DecodingError {
                    print("❌ Decoding Error Details: \(error)")
                    return APIError.decodingError
                } else if let apiError = error as? APIError {
                    return apiError
                } else {
                    return APIError.networkError(error.localizedDescription)
                }
            }
            .eraseToAnyPublisher()
    }
    
    func deleteMedication(id: Int) -> AnyPublisher<Void, APIError> {
        print("💊 Starting deleteMedication API call...")
        print("📡 Endpoint: /medications/\(id)/")
        
        let url = baseURL + "/medications/\(id)/"
        print("🌐 Full URL: \(url)")
        
        // Add Firebase token from login response if available
        if let token = SessionManager().authToken {
            print("🔐 Using Firebase token for authentication: \(String(token.prefix(20)))...")
        } else {
            print("⚠️ No Firebase token available - request will be sent without authentication")
        }
        
        // Create custom URLSession with HTTP/3 configuration
        let config = URLSessionConfiguration.ephemeral
        config.httpMaximumConnectionsPerHost = 6 // HTTP/3 supports multiple streams
        config.httpShouldUsePipelining = true // HTTP/3 supports multiplexing
        config.allowsCellularAccess = true
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        // Enable HTTP/3 and modern protocols
        if #available(iOS 15.0, *) {
            config.allowsConstrainedNetworkAccess = true
            config.allowsExpensiveNetworkAccess = true
        }
        
        config.httpAdditionalHeaders = [
            "User-Agent": "ZorgamIOS/1.0 (iOS; HTTP/3)"
        ]
        let customSession = URLSession(configuration: config)
        
        // Create URLRequest with proper headers
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "DELETE"
        request.timeoutInterval = 30.0
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        // HTTP/3 doesn't need Connection headers - handled by QUIC protocol
        
        // Add Firebase token from login response if available
        if let token = SessionManager().authToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔐 Using Firebase token for authentication: \(String(token.prefix(20)))...")
        } else {
            print("⚠️ No Firebase token available - request will be sent without authentication")
        }
        
        return customSession.dataTaskPublisher(for: request)
            .tryMap { data, response -> Void in
                // Log response size and status
                let dataSize = data.count
                print("📊 Response size: \(dataSize) bytes (\(String(format: "%.2f", Double(dataSize) / 1024.0)) KB)")
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 HTTP Status Code: \(httpResponse.statusCode)")
                    print("📡 HTTP Version: \(httpResponse.value(forHTTPHeaderField: "HTTP-Version") ?? "Unknown")")
                    print("📡 Response Headers: \(httpResponse.allHeaderFields)")
                    
                    if httpResponse.statusCode >= 400 {
                        throw APIError.serverError("Server returned status code: \(httpResponse.statusCode)")
                    }
                }
                
                // Log raw response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🔍 Raw API Response:")
                    print("=====================================")
                    print(responseString)
                    print("=====================================")
                } else {
                    print("❌ Could not convert response data to string")
                    // Log first 100 bytes as hex for debugging
                    let hexString = data.prefix(100).map { String(format: "%02x", $0) }.joined(separator: " ")
                    print("🔍 First 100 bytes (hex): \(hexString)")
                }
                
                return ()
            }
            .retry(2)
            .receive(on: DispatchQueue.main)
            .handleEvents(
                receiveOutput: { _ in
                    print("✅ deleteMedication API Response received - medication deleted successfully")
                },
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("✅ deleteMedication API call completed successfully")
                    case .failure(let error):
                        print("❌ deleteMedication API Error: \(error)")
                    }
                }
            )
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                } else {
                    return APIError.networkError(error.localizedDescription)
                }
            }
            .eraseToAnyPublisher()

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
    
    func getQuestionnaireById(questionnaireId: Int, checkinType: String) -> AnyPublisher<[Questionnaire], APIError> {
        let checkinTypeLower = checkinType.lowercased()
        print("🌐 Making API call to: \(baseURL)/questionnaires/comprehensive/checkin/\(checkinTypeLower)")
        print("📋 Questionnaire ID: \(questionnaireId)")
        
        guard let url = URL(string: baseURL + "/questionnaires/comprehensive/checkin/\(checkinTypeLower)") else {
            print("❌ Invalid URL: \(baseURL)/questionnaires/comprehensive/checkin/\(checkinTypeLower)")
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("\(questionnaireId)", forHTTPHeaderField: "questionnaire_id")
        
        // Add auth token if available
        if let token = SessionManager().authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔑 Using auth token for request")
        } else {
            print("⚠️ No auth token available")
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                print("📡 API Response received for questionnaire ID: \(questionnaireId)")
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
            .decode(type: [Questionnaire].self, decoder: JSONDecoder())
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
    
    func submitQuestionnaire(submission: QuestionnaireSubmission) -> AnyPublisher<SubmissionResponse, APIError> {
        print("🌐 Making API call to: \(baseURL)/questionnaires/submissions")
        print("📤 Submission data: \(submission)")
        return performRequest<QuestionnaireSubmission, SubmissionResponse>(endpoint: "/questionnaires/submissions", method: "POST", body: submission)
    }
    
    // MARK: - Points API
    func getMyTotalPoints() -> AnyPublisher<Int, APIError> {
        print("🌐 Making API call to: \(baseURL)/points/me/total/")
        return performGetRequest<Int>(endpoint: "/points/me/total/")
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

     func getSubmissions(aggregate: Bool = false, sortBy: String? = nil, sortOrder: String? = nil) -> AnyPublisher<[SubmissionResponses], APIError> {
        print("📋 Starting getSubmissions API call...")
        print("📡 Endpoint: /questionnaires/submissions")
        print("🔧 URL Parameters: aggregate=\(aggregate), sortBy=\(sortBy ?? "none"), sortOrder=\(sortOrder ?? "none")")
        
        var urlComponents = URLComponents(string: baseURL + "/questionnaires/submissions")
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "aggregate", value: "false")
        ]
        
        if let sortBy = sortBy {
            queryItems.append(URLQueryItem(name: "sort_by", value: sortBy))
        }
        
        if let sortOrder = sortOrder {
            queryItems.append(URLQueryItem(name: "sort_order", value: sortOrder))
        }
        
        urlComponents?.queryItems = queryItems
        let urlString = urlComponents?.url?.absoluteString ?? baseURL + "/questionnaires/submissions?aggregate=false"
        print("🌐 Full URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url, timeoutInterval: 30.0) // Reduced from infinity to 30 seconds
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData // Force fresh data
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // HTTP/3 doesn't need Connection headers - handled by QUIC protocol
        // HTTP/3 handles connection management automatically via QUIC
        
        // Add Firebase token from login response if available
        if let token = SessionManager().authToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔐 Using Firebase token for authentication: \(String(token.prefix(20)))...")
        } else {
            print("⚠️ No Firebase token available - request will be sent without authentication")
        }
        
        // Create a custom URLSession configuration optimized for HTTP/3
        let config = URLSessionConfiguration.ephemeral
        config.httpMaximumConnectionsPerHost = 6 // HTTP/3 supports multiple streams
        config.httpShouldUsePipelining = true // HTTP/3 supports multiplexing
        config.allowsCellularAccess = true
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        // Enable HTTP/3 and modern protocols
        if #available(iOS 15.0, *) {
            config.allowsConstrainedNetworkAccess = true
            config.allowsExpensiveNetworkAccess = true
        }
        
        config.httpAdditionalHeaders = [
            "User-Agent": "ZorgamIOS/1.0 (iOS; HTTP/3)"
        ]
        
        let customSession = URLSession(configuration: config)
        
        return customSession.dataTaskPublisher(for: request)
            .retry(2) // Retry up to 2 times on failure
            .tryMap { data, response -> Data in
                // Log response size and status
                let dataSize = data.count
                print("📊 Response size: \(dataSize) bytes (\(String(format: "%.2f", Double(dataSize) / 1024.0)) KB)")
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 HTTP Status Code: \(httpResponse.statusCode)")
                    print("📡 HTTP Version: \(httpResponse.value(forHTTPHeaderField: "HTTP-Version") ?? "Unknown")")
                    print("📡 Response Headers: \(httpResponse.allHeaderFields)")
                    
                    // Check for HTTP errors
                    if httpResponse.statusCode >= 400 {
                        print("❌ HTTP Error: \(httpResponse.statusCode)")
                        throw APIError.serverError("HTTP \(httpResponse.statusCode)")
                    }
                } else {
                    print("⚠️ Response is not HTTPURLResponse: \(type(of: response))")
                }
                
                // Log raw response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🔍 Raw API Response:")
                    print("=====================================")
                    print(responseString)
                    print("=====================================")
                } else {
                    print("❌ Could not convert response data to string")
                    // Try to log as hex for debugging
                    let hexString = data.map { String(format: "%02x", $0) }.joined(separator: " ")
                    print("🔍 Raw data (hex): \(String(hexString.prefix(200)))...")
                }
                
                return data
            }
            .decode(type: [SubmissionResponses].self, decoder: JSONDecoder())
            .mapError { error in
                if error is DecodingError {
                    print("❌ Decoding Error Details: \(error)")
                    return APIError.decodingError
                } else if let apiError = error as? APIError {
                    return apiError
                } else {
                    print("❌ Network Error Details: \(error)")
                    return APIError.networkError(error.localizedDescription)
                }
            }
            .receive(on: DispatchQueue.main)
            .handleEvents(
                receiveOutput: { submissions in
                    print("✅ getSubmissions API Response received:")
                    print("🔍 Raw getSubmissions Response:")
                    print("=====================================")
                    print("📊 Total submissions: \(submissions.count)")
                    
                    if submissions.isEmpty {
                        print("📭 No submissions found in API response")
                    } else {
                        // Print each submission with detailed formatting
                        for (index, submission) in submissions.enumerated() {
                            print("📋 Submission \(index + 1):")
                            print("   🆔 ID: \(submission.id)")
                            print("   👤 User ID: \(submission.userId)")
                            print("   📝 Questionnaire ID: \(submission.questionnaireId)")
                            print("   📅 Checkin Type: \(submission.checkinType)")
                            print("   ⏰ Submitted at: \(submission.submittedAt)")
                            print("   ✅ Status: \(submission.status)")
                            print("   💬 Nurse Comments: \(submission.nurseComments ?? "None")")
                            print("   📄 Answers JSON: \(submission.answersJson)")
                            print("   " + String(repeating: "-", count: 40))
                        }
                    }
                    
                    print("=====================================")
                },
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("✅ getSubmissions API call completed successfully")
                    case .failure(let error):
                        print("❌ getSubmissions API Error: \(error.localizedDescription)")
                    }
                }
            )
            .eraseToAnyPublisher()
    }
    
    // MARK: - Generic Request Method
    private func performRequest<R: Codable>(
        endpoint: String,
        method: String,
        body: (any Codable)? = nil
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
            print("🔐 Using Firebase token for authentication: \(String(token.prefix(20)))...")
        } else {
            print("⚠️ No authentication token available")
        }
        
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                return Fail(error: APIError.encodingError)
                    .eraseToAnyPublisher()
            }
        }
        
        // Use standard URLSession exactly like Postman
        let customSession = URLSession.shared
        
        return customSession.dataTaskPublisher(for: request)
            .retry(2) // Retry up to 2 times on failure
            .tryMap { data, response -> Data in
                // Log response size and status
                let dataSize = data.count
                print("📊 Response size: \(dataSize) bytes (\(String(format: "%.2f", Double(dataSize) / 1024.0)) KB)")
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 HTTP Status Code: \(httpResponse.statusCode)")
                    print("📡 HTTP Version: \(httpResponse.value(forHTTPHeaderField: "HTTP-Version") ?? "Unknown")")
                    print("📡 Response Headers: \(httpResponse.allHeaderFields)")
                    
                    // Log raw response for debugging BEFORE checking status code
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("🔍 Raw API Response:")
                        print("=====================================")
                        print(responseString)
                        print("=====================================")
                    } else {
                        print("❌ Could not convert response data to string")
                    }
                    
                    // Check HTTP status code AFTER logging
                    if httpResponse.statusCode >= 400 {
                        throw APIError.serverError("Server returned status code: \(httpResponse.statusCode)")
                    }
                }
                
                return data
            }
            .decode(type: R.self, decoder: JSONDecoder())
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                } else if error is DecodingError {
                    print("❌ Decoding Error Details: \(error)")
                    return APIError.decodingError
                } else {
                    return APIError.networkError(error.localizedDescription)
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Generic Request Method with Full URL
    private func performRequestWithURL<R: Codable>(
        url: String,
        method: String,
        body: (any Codable)? = nil
    ) -> AnyPublisher<R, APIError> {
        guard let requestURL = URL(string: url) else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth token if available
        if let token = SessionManager().authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔐 Using Firebase token for authentication: \(String(token.prefix(20)))...")
        } else {
            print("⚠️ No authentication token available")
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
                // Log response size
                let dataSize = data.count
                print("📊 Response size: \(dataSize) bytes (\(String(format: "%.2f", Double(dataSize) / 1024.0)) KB)")
                
                // Check HTTP status code
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 HTTP Status Code: \(httpResponse.statusCode)")

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

// MARK: - Checkin Type
enum CheckinType: String, CaseIterable, Codable {
    case daily = "DAILY"
    case weekly = "WEEKLY"
    case monthly = "MONTHLY"
    case oneTime = "ONE_TIME"
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .oneTime: return "One-time"
        }
    }
}

// MARK: - Questionnaire Response
struct QuestionnaireResponse: Codable {
    let id: Int
    let title: String
    let description: String
    let questions: [QuestionnaireQuestion]
}

// MARK: - Questionnaire Question
//struct QuestionnaireQuestion: Codable {
//    let id: Int
//    let title: String
//    let subtitle: String?
//    let questionType: String
//    let options: [QuestionnaireOption]
//    let isRequired: Bool
//    let key: String
//    let sequence: Int
//    
//    enum CodingKeys: String, CodingKey {
//        case id, title, subtitle, key, sequence
//        case questionType = "question_type"
//        case isRequired = "is_required"
//        case options
//    }
//}


// MARK: - Questionnaire Option
//struct QuestionnaireOption: Codable {
//    let id: Int
//    let label: String
//    let value: String
//}

// MARK: - Submission Request
struct SubmissionRequest: Codable {
    let questionnaireId: Int
    let answersJson: [String: String]
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case questionnaireId = "questionnaire_id"
        case answersJson = "answers_json"
        case status
    }
}

// MARK: - Submission Response
//struct SubmissionResponses: Codable {
//    let id: Int
//    let userId: Int
//    let questionnaireId: Int
//    let checkinType: String
//    let answersJson: [String: Any]
//    let status: String
//    let nurseComments: String?
//    let submittedAt: String
//    let createdAt: String
//    let updatedAt: String
//    let alertLevel: String
//    let diseaseId: Int
//    let diseaseName: String
//    let reviewedByNurseId: Int?
//    let reviewedAt: String?
//    let user: String?
//    let reviewedByNurse: String?
//    
//    enum CodingKeys: String, CodingKey {
//        case id, status
//        case userId = "user_id"
//        case questionnaireId = "questionnaire_id"
//        case checkinType = "checkin_type"
//        case answersJson = "answers_json"
//        case nurseComments = "nurse_comments"
//        case submittedAt = "submitted_at"
//        case createdAt = "created_at"
//        case updatedAt = "updated_at"
//        case alertLevel = "alert_level"
//        case diseaseId = "disease_id"
//        case diseaseName = "disease_name"
//        case reviewedByNurseId = "reviewed_by_nurse_id"
//        case reviewedAt = "reviewed_at"
//        case user
//        case reviewedByNurse = "reviewed_by_nurse"
//    }
//}

struct SubmissionResponses: Codable, Equatable {
    let id: Int
    let userId: Int
    let questionnaireId: Int
    let checkinType: String
    let answersJson: [String: Any]
    let status: String
    let nurseComments: String?
    let submittedAt: String
    let createdAt: String
    let updatedAt: String
    let alertLevel: String
    let diseaseId: Int
    let diseaseName: String
    let reviewedByNurseId: Int?
    let reviewedAt: String?
    let user: String?
    let reviewedByNurse: String?
    
    enum CodingKeys: String, CodingKey {
        case id, status
        case userId = "user_id"
        case questionnaireId = "questionnaire_id"
        case checkinType = "checkin_type"
        case answersJson = "answers_json"
        case nurseComments = "nurse_comments"
        case submittedAt = "submitted_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case alertLevel = "alert_level"
        case diseaseId = "disease_id"
        case diseaseName = "disease_name"
        case reviewedByNurseId = "reviewed_by_nurse_id"
        case reviewedAt = "reviewed_at"
        case user
        case reviewedByNurse = "reviewed_by_nurse"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        userId = try container.decode(Int.self, forKey: .userId)
        questionnaireId = try container.decode(Int.self, forKey: .questionnaireId)
        checkinType = try container.decode(String.self, forKey: .checkinType)
        status = try container.decode(String.self, forKey: .status)
        nurseComments = try container.decodeIfPresent(String.self, forKey: .nurseComments)
        submittedAt = try container.decode(String.self, forKey: .submittedAt)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        alertLevel = try container.decode(String.self, forKey: .alertLevel)
        diseaseId = try container.decode(Int.self, forKey: .diseaseId)
        diseaseName = try container.decode(String.self, forKey: .diseaseName)
        reviewedByNurseId = try container.decodeIfPresent(Int.self, forKey: .reviewedByNurseId)
        reviewedAt = try container.decodeIfPresent(String.self, forKey: .reviewedAt)
        user = try container.decodeIfPresent(String.self, forKey: .user)
        reviewedByNurse = try container.decodeIfPresent(String.self, forKey: .reviewedByNurse)
        
        // Custom decoding for answersJson to handle mixed types
        let answersContainer = try container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: .answersJson)
        var answers: [String: Any] = [:]
        
        for key in answersContainer.allKeys {
            if let stringValue = try? answersContainer.decode(String.self, forKey: key) {
                answers[key.stringValue] = stringValue
            } else if let boolValue = try? answersContainer.decode(Bool.self, forKey: key) {
                answers[key.stringValue] = boolValue
            } else if let intValue = try? answersContainer.decode(Int.self, forKey: key) {
                answers[key.stringValue] = intValue
            } else if let doubleValue = try? answersContainer.decode(Double.self, forKey: key) {
                answers[key.stringValue] = doubleValue
            }
        }
        
        answersJson = answers
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(questionnaireId, forKey: .questionnaireId)
        try container.encode(checkinType, forKey: .checkinType)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(nurseComments, forKey: .nurseComments)
        try container.encode(submittedAt, forKey: .submittedAt)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(alertLevel, forKey: .alertLevel)
        try container.encode(diseaseId, forKey: .diseaseId)
        try container.encode(diseaseName, forKey: .diseaseName)
        try container.encodeIfPresent(reviewedByNurseId, forKey: .reviewedByNurseId)
        try container.encodeIfPresent(reviewedAt, forKey: .reviewedAt)
        try container.encodeIfPresent(user, forKey: .user)
        try container.encodeIfPresent(reviewedByNurse, forKey: .reviewedByNurse)
        
        // Custom encoding for answersJson
        var answersContainer = container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: .answersJson)
        for (key, value) in answersJson {
            let codingKey = DynamicCodingKey(stringValue: key)!
            if let stringValue = value as? String {
                try answersContainer.encode(stringValue, forKey: codingKey)
            } else if let boolValue = value as? Bool {
                try answersContainer.encode(boolValue, forKey: codingKey)
            } else if let intValue = value as? Int {
                try answersContainer.encode(intValue, forKey: codingKey)
            } else if let doubleValue = value as? Double {
                try answersContainer.encode(doubleValue, forKey: codingKey)
            }
        }
    }
    
    // MARK: - Regular Initializer for Testing/Preview
    init(
        id: Int,
        userId: Int,
        questionnaireId: Int,
        checkinType: String,
        answersJson: [String: Any],
        status: String,
        nurseComments: String?,
        submittedAt: String,
        createdAt: String,
        updatedAt: String,
        alertLevel: String,
        diseaseId: Int,
        diseaseName: String,
        reviewedByNurseId: Int?,
        reviewedAt: String?,
        user: String?,
        reviewedByNurse: String?
    ) {
        self.id = id
        self.userId = userId
        self.questionnaireId = questionnaireId
        self.checkinType = checkinType
        self.answersJson = answersJson
        self.status = status
        self.nurseComments = nurseComments
        self.submittedAt = submittedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.alertLevel = alertLevel
        self.diseaseId = diseaseId
        self.diseaseName = diseaseName
        self.reviewedByNurseId = reviewedByNurseId
        self.reviewedAt = reviewedAt
        self.user = user
        self.reviewedByNurse = reviewedByNurse
    }
    
    // MARK: - Equatable
    static func == (lhs: SubmissionResponses, rhs: SubmissionResponses) -> Bool {
        return lhs.id == rhs.id &&
               lhs.userId == rhs.userId &&
               lhs.questionnaireId == rhs.questionnaireId &&
               lhs.checkinType == rhs.checkinType &&
               lhs.status == rhs.status &&
               lhs.nurseComments == rhs.nurseComments &&
               lhs.submittedAt == rhs.submittedAt &&
               lhs.createdAt == rhs.createdAt &&
               lhs.updatedAt == rhs.updatedAt &&
               lhs.alertLevel == rhs.alertLevel &&
               lhs.diseaseId == rhs.diseaseId &&
               lhs.diseaseName == rhs.diseaseName &&
               lhs.reviewedByNurseId == rhs.reviewedByNurseId &&
               lhs.reviewedAt == rhs.reviewedAt &&
               lhs.user == rhs.user &&
               lhs.reviewedByNurse == rhs.reviewedByNurse &&
               NSDictionary(dictionary: lhs.answersJson).isEqual(to: rhs.answersJson)
    }
}

// Helper struct for dynamic coding keys
struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}


