import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    // MARK: - Environment Objects
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var navigationManager: NavigationManager
    
    // MARK: - State
    @State private var showingLogoutAlert = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    @State private var showingProfile = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section {
                    Button(action: {
                        showingProfile = true
                    }) {
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
                                    .foregroundColor(.primary)
                                
                                Text(sessionManager.currentUser?.email ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // App Section
                Section("App") {
                    HStack(spacing: 16) {
                        Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                            .foregroundColor(.blue)
                            .frame(width: 24, height: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dark Mode")
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Text(isDarkMode ? "Dark" : "Light")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $isDarkMode)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                    }
                    .padding(.vertical, 4)
                    
                    SettingsRow(
                        icon: "globe",
                        title: "Language",
                        subtitle: "Coming Soon",
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
                        action: {
                            showingPrivacyPolicy = true
                        }
                    )
                    
                    SettingsRow(
                        icon: "doc.text.fill",
                        title: "Terms of Service",
                        subtitle: "Read our terms of service",
                        action: {
                            showingTermsOfService = true
                        }
                    )
                }
                
                // Account Section
                Section("Account") {
                    SettingsRow(
                        icon: "person.circle.fill",
                        title: "Profile",
                        subtitle: "Edit your personal information",
                        action: {
                            showingProfile = true
                        }
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
            .sheet(isPresented: $showingPrivacyPolicy) {
                PrivacyPolicyContentView()
                    .preferredColorScheme(isDarkMode ? .dark : .light)
            }
            .sheet(isPresented: $showingTermsOfService) {
                TermsOfServiceContentView()
                    .preferredColorScheme(isDarkMode ? .dark : .light)
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
                    .preferredColorScheme(isDarkMode ? .dark : .light)
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
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

// MARK: - Privacy Policy Content View
struct PrivacyPolicyContentView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Privacy Policy Content Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Privacy Policy")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Last updated: June 13, 2025")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("This Privacy Policy describes Our policies and procedures on the collection, use and disclosure of Your information when You use LaennecAI and tells You about Your privacy rights and how the law protects You.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                        
                        Text("LaennecAI is an educational and experimental application that allows you to record, play back, and explore heart and lung sounds using your smartphone. We prioritize your privacy and data protection. By using LaennecAI, You agree to the collection and use of information in accordance with this Privacy Policy.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                        
                        PrivacySectionView(
                            title: "Interpretation and Definitions",
                            content: "The words of which the initial letter is capitalized have meanings defined under the following conditions. The following definitions shall have the same meaning regardless of whether they appear in singular or in plural."
                        )
                        
                        PrivacySectionView(
                            title: "Definitions",
                            content: "For the purposes of this Privacy Policy:\n\n• Application refers to LaennecAI, the software program provided by the Company for recording, playing back, and exploring heart and lung sounds.\n\n• Company (referred to as either \"the Company\", \"We\", \"Us\" or \"Our\" in this Agreement) refers to LaennecAI.\n\n• Device means any smartphone or mobile device that can access the Application.\n\n• Personal Data is any information that relates to an identified or identifiable individual, including but not limited to name, email address, and feedback provided through our feedback form.\n\n• Service refers to the LaennecAI Application.\n\n• Heart and Lung Sound Data refers to audio recordings of heart and lung sounds captured using your device's microphone.\n\n• Feedback Data refers to information provided through our feedback form, including your name, email, and feedback about the Application.\n\n• You means the individual accessing or using the LaennecAI Application."
                        )
                        
                        PrivacySectionView(
                            title: "Data Collection and Storage",
                            content: "LaennecAI prioritizes your privacy and data protection. Here's what we collect and how we handle your data:\n\nData We Collect:\n• Feedback Data: When you use our feedback form, we collect your name, email address, and feedback about the Application\n• Heart and Lung Sound Data: Audio recordings captured using your device's microphone (stored locally on your device only)\n\nData We DO NOT Collect:\n• We do not collect, transmit, or store any of your heart and lung sound recordings on our servers\n• We do not collect personal health information beyond what you voluntarily provide in feedback\n• We do not track your location or other personal data\n\nAll heart and lung sound recordings are stored locally on your device only. You have full control over this data and can access, share, or delete your recordings at any time directly within the app."
                        )
                        
                        PrivacySectionView(
                            title: "How We Use Your Information",
                            content: "We use the information we collect for the following purposes:\n\n• To provide and maintain LaennecAI: To enable you to record, play back, and explore heart and lung sounds using your smartphone\n\n• To improve our Application: We use feedback data to understand how to improve LaennecAI's functionality and user experience\n\n• To respond to your feedback: When you contact us through our feedback form, we use your provided information to respond to your inquiries\n\n• For educational purposes: LaennecAI is designed for educational and experimental use to help users learn about heart and lung sounds\n\nWe do not use your heart and lung sound recordings for any purpose other than what you choose to do with them locally on your device. All audio data remains under your complete control."
                        )
                        
                        PrivacySectionView(
                            title: "Information Sharing and Disclosure",
                            content: "LaennecAI is committed to protecting your privacy. Here's how we handle information sharing:\n\nWe DO NOT share your personal information in the following ways:\n• We do not sell, trade, or otherwise transfer your personal information to third parties\n• We do not share your heart and lung sound recordings with anyone\n• We do not share your feedback data with third parties without your explicit consent\n\nWe may share information only in these limited circumstances:\n• With your explicit consent: We may share your feedback data only if you explicitly consent to such sharing\n• For legal compliance: We may disclose information if required by law or to protect our rights\n\nYour heart and lung sound recordings are never shared, transmitted, or stored on our servers. They remain completely private and under your control on your device."
                        )
                        
                        PrivacySectionView(
                            title: "Data Retention and Your Rights",
                            content: "Data Retention:\n• Heart and Lung Sound Data: Stored locally on your device only. You control when to delete these recordings\n• Feedback Data: We retain feedback data only as long as necessary to respond to your inquiries and improve our Application\n\nYour Rights (GDPR Compliance):\n• Right to Access: You can request access to any personal data we hold about you\n• Right to Rectification: You can request correction of any inaccurate personal data\n• Right to Erasure: You can request deletion of your personal data\n• Right to Data Portability: You can request a copy of your data in a structured format\n• Right to Object: You can object to processing of your personal data\n\nTo exercise these rights, please contact us at geo.paulson@laennec.ai"
                        )
                        
                        PrivacySectionView(
                            title: "Data Security and Local Storage",
                            content: "LaennecAI prioritizes your data security through local storage:\n\n• Local Storage Only: All heart and lung sound recordings are stored exclusively on your device\n• No Server Transmission: We do not transmit or store your audio data on our servers\n• Device Security: Your data is protected by your device's built-in security measures\n• No Cloud Storage: We do not use cloud storage services for your personal audio data\n\nYour heart and lung sound recordings remain completely private and secure on your device. You have full control over this data and can delete it at any time through the Application."
                        )
                        
                        PrivacySectionView(
                            title: "Managing Your Data",
                            content: "You have complete control over your data in LaennecAI:\n\n• Heart and Lung Sound Recordings: You can delete these recordings at any time directly within the Application\n• Feedback Data: You can request deletion of your feedback data by contacting us\n• No Account Required: LaennecAI does not require account creation, so there's no account data to manage\n\nTo delete your feedback data or exercise any of your privacy rights, please contact us at geo.paulson@laennec.ai"
                        )
                        
                        PrivacySectionView(
                            title: "Important Disclaimers",
                            content: "LaennecAI is an educational and experimental application:\n\n• Not a Medical Device: LaennecAI is not a clinical tool and does not detect, diagnose, or treat any medical condition\n• Educational Purpose Only: The Application is designed for educational and experimental use to help users learn about heart and lung sounds\n• No Medical Advice: For health advice, please consult your doctor or a healthcare professional\n• Device Compatibility: If you have a cardiac device (pacemaker or defibrillator), be aware of potential interference between your mobile phone and the device"
                        )
                        
                        PrivacySectionView(
                            title: "Children's Privacy",
                            content: "LaennecAI is designed for educational purposes and may be used by individuals of all ages under appropriate supervision. However, we do not knowingly collect personal information from children under 13 without parental consent. If you are a parent or guardian and believe your child has provided us with personal information, please contact us at geo.paulson@laennec.ai"
                        )
                        
                        PrivacySectionView(
                            title: "Changes to this Privacy Policy",
                            content: "We may update this Privacy Policy from time to time to reflect changes in our practices or for other operational, legal, or regulatory reasons. We will notify you of any material changes by:\n\n• Posting the updated Privacy Policy in the Application\n• Updating the \"Last updated\" date at the top of this Privacy Policy\n\nWe encourage you to review this Privacy Policy periodically to stay informed about how we protect your information."
                        )
                        
                        PrivacySectionView(
                            title: "Contact Us",
                            content: "If you have any questions about this Privacy Policy or LaennecAI, please contact us:\n\n• Website: www.laennec.ai\n• Email: geo.paulson@laennec.ai\n\nWe're committed to building a future where everyone is more informed and engaged in their heart and lung health through innovative educational tools like LaennecAI."
                        )
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Terms of Service Content View
struct TermsOfServiceContentView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Terms and Conditions Content Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Terms and Conditions")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Welcome to LaennecAI: Your Gateway to Exploring Heart Sounds")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("LaennecAI invites you to experience and learn about the unique rhythms of your heart and lungs using just your smartphone. Our app allows you to record, play back, and explore these vital sounds, contributing to a better understanding of body sounds in a non-clinical, educational context.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                        
                        TermsSectionView(
                            title: "Please Note:",
                            content: "Your use of LaennecAI is subject to the following terms; if you do not agree to all of the following, you may not use LaennecAI in any manner. LaennecAI is not a clinical tool. It does not detect, diagnose, or treat any medical condition from your body sounds. It is experimental and educational in nature. For health advice, please consult your doctor or a healthcare professional."
                        )
                        
                        TermsSectionView(
                            title: "Data Protection and Anonymity:",
                            content: "LaennecAI prioritises your privacy. All data, including heart and lung sound recordings, is stored locally on your device. We do not collect, transmit, or store any of your data on our servers. You have full control over your data. You can access, share, or delete your recordings at any time, directly within the app."
                        )
                        
                        TermsSectionView(
                            title: "Privacy Assurance:",
                            content: "LaennecAI's feedback form collects your name, email, and feedback to improve the app. We guarantee your information will not be shared with third parties, protecting your privacy. In compliance with GDPR, we ensure the security of your data and uphold your rights to access, correct, or delete it. For detailed information on our privacy practices, please consult our Privacy Policy."
                        )
                        
                        TermsSectionView(
                            title: "Health and Safety:",
                            content: "LaennecAI uses your phone's microphone to record body sounds and has no known adverse effect on your health. If you have a cardiac device (like a pacemaker or defibrillator), be aware of potential interference between your mobile phone and the device. While there is no conclusive scientific evidence of any risk, please follow any instructions or advice from your device manufacturer."
                        )
                        
                        Text("We reserve the right to update these terms and the functionality of LaennecAI at any time. Continued use of the app after changes indicates your acceptance of these new terms.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                        
                        TermsSectionView(
                            title: "Contact and Support:",
                            content: "For any questions or support related to LaennecAI, please contact us by visiting our website at \"www.laennec.ai\". By using LaennecAI, you embark on an innovative journey of discovery, contributing to our collective understanding of cardiovascular health. We're committed to building a future where everyone is more informed and engaged in their heart and lung health."
                        )
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Terms and Conditions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Privacy Section View
struct PrivacySectionView: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
    }
}

// MARK: - Terms Section View
struct TermsSectionView: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environmentObject(SessionManager())
        .environmentObject(NavigationManager())
}
