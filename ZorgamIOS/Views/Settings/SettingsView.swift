import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    // MARK: - Environment Objects
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var navigationManager: NavigationManager
    
    // MARK: - State
    @State private var showingLogoutAlert = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(sessionManager.currentUser?.fullName ?? "User")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(sessionManager.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                // Health Section
                Section("Health") {
                    SettingsRow(
                        icon: "heart.fill",
                        title: "Health Data",
                        subtitle: "Manage your health information",
                        action: {}
                    )
                    
                    SettingsRow(
                        icon: "bell.fill",
                        title: "Reminders",
                        subtitle: "Set up medication reminders",
                        action: {}
                    )
                    
                    SettingsRow(
                        icon: "square.and.arrow.up",
                        title: "Export Data",
                        subtitle: "Export your health data",
                        action: {}
                    )
                }
                
                // App Section
                Section("App") {
                    SettingsRow(
                        icon: "moon.fill",
                        title: "Dark Mode",
                        subtitle: "System",
                        action: {}
                    )
                    
                    SettingsRow(
                        icon: "globe",
                        title: "Language",
                        subtitle: "English",
                        action: {}
                    )
                    
                    SettingsRow(
                        icon: "info.circle.fill",
                        title: "About",
                        subtitle: "Version 1.0.0",
                        action: {}
                    )
                }
                
                // Support Section
                Section("Support") {
                    SettingsRow(
                        icon: "questionmark.circle.fill",
                        title: "Help & Support",
                        subtitle: "Get help and contact support",
                        action: {}
                    )
                    
                    SettingsRow(
                        icon: "doc.text.fill",
                        title: "Privacy Policy",
                        subtitle: "Read our privacy policy",
                        action: {}
                    )
                    
                    SettingsRow(
                        icon: "doc.text.fill",
                        title: "Terms of Service",
                        subtitle: "Read our terms of service",
                        action: {}
                    )
                }
                
                // Account Section
                Section("Account") {
                    SettingsRow(
                        icon: "person.circle.fill",
                        title: "Edit Profile",
                        subtitle: "Update your personal information",
                        action: {}
                    )
                    
                    SettingsRow(
                        icon: "key.fill",
                        title: "Change Password",
                        subtitle: "Update your password",
                        action: {}
                    )
                    
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                                .frame(width: 24, height: 24)
                            
                            Text("Sign Out")
                                .foregroundColor(.red)
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Sign Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    sessionManager.logout()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environmentObject(SessionManager())
        .environmentObject(NavigationManager())
}
