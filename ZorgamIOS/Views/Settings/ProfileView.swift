import SwiftUI
import PhotosUI

// MARK: - Profile View
struct ProfileView: View {
    // MARK: - Environment Objects
    @EnvironmentObject private var sessionManager: SessionManager
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @State private var profileImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingActionSheet = false
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Picture Card
                    ProfilePictureCard(
                        profileImage: profileImage,
                        userName: sessionManager.currentUser?.fullName ?? "User",
                        userEmail: sessionManager.currentUser?.email ?? "",
                        onEditTapped: {
                            showingActionSheet = true
                        }
                    )
                    
                    // Profile Information Card
                    ProfileInformationCard(
                        user: sessionManager.currentUser
                    )
                }
                .padding(.horizontal)
                .padding(.vertical, 20)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("Select Profile Picture"),
                buttons: [
                    .default(Text("Take Photo")) {
                        showingCamera = true
                    },
                    .default(Text("Choose from Library")) {
                        showingPhotoLibrary = true
                    },
                    .cancel()
                ]
            )
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(sourceType: .camera) { image in
                profileImage = image
            }
        }
        .sheet(isPresented: $showingPhotoLibrary) {
            ImagePicker(sourceType: .photoLibrary) { image in
                profileImage = image
            }
        }
    }
}

// MARK: - Profile Picture Card
struct ProfilePictureCard: View {
    let profileImage: UIImage?
    let userName: String
    let userEmail: String
    let onEditTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Picture with Edit Button
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .overlay(
                        Group {
                            if let image = profileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            } else {
                                // Show first letter of name
                                Text(String(userName.prefix(1)).uppercased())
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    )
                
                // Edit Button
                Button(action: onEditTapped) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                }
                .offset(x: 40, y: 40)
            }
            
            // User Name
            Text(userName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Email
            Text(userEmail)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Profile Information Card
struct ProfileInformationCard: View {
    let user: User?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Title
            Text("Profile Information")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // Profile Details
            VStack(spacing: 12) {
                ProfileDetailRow(
                    label: "Full Name",
                    value: user?.fullName ?? "N/A"
                )
                
                ProfileDetailRow(
                    label: "Email Address",
                    value: user?.email ?? "N/A"
                )
                
                ProfileDetailRow(
                    label: "Account Status",
                    value: "Active"
                )
                
                ProfileDetailRow(
                    label: "Role",
                    value: user?.role.capitalized ?? "N/A"
                )
                
                ProfileDetailRow(
                    label: "Region",
                    value: user?.regionCode ?? "N/A"
                )
                
                ProfileDetailRow(
                    label: "Disease ID",
                    value: user?.diseaseId.description ?? "N/A"
                )
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Profile Detail Row
struct ProfileDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview
#Preview {
    ProfileView()
        .environmentObject(SessionManager())
}
