import SwiftUI

// MARK: - Welcome View
struct WelcomeView: View {
    // MARK: - Environment Objects
    @EnvironmentObject private var sessionManager: SessionManager
    
    // MARK: - State
    @StateObject private var viewModel = WelcomeViewModel()
    @State private var showingAlert = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Welcome to Zorgam")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Your personal health companion")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 50)
                
                Spacer()
                
                // Login Form
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Enter your username", text: $viewModel.username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        SecureField("Enter your password", text: $viewModel.password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 30)
                
                // Login Button
                Button(action: {
                    viewModel.login { result in
                        switch result {
                        case .success(let response):
                            sessionManager.login(response: response)
                        case .failure(let error):
                            viewModel.errorMessage = error
                        case .loading:
                            break
                        }
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(viewModel.isLoading ? "Signing In..." : "Sign In")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(viewModel.isFormValid ? Color.blue : Color.gray)
                    .cornerRadius(10)
                }
                .disabled(!viewModel.isFormValid || viewModel.isLoading)
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Footer
                VStack(spacing: 8) {
                    Text("Don't have an account?")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Contact Support") {
                        // Handle support contact
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
        }
        .alert("Login Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
    }
}

// MARK: - Preview
#Preview {
    WelcomeView()
        .environmentObject(SessionManager())
}
