import SwiftUI

struct ProfilePictureView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel

    let editableMode: Bool
    @State private var profileImage: UIImage?
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary

    var body: some View {
        if editableMode {
            Menu {
                Button("Take Photo", systemImage: "camera") {
                    self.sourceType = .camera
                    self.showImagePicker = true
                }
                Button("Choose from Library", systemImage: "photo.on.rectangle") {
                    self.sourceType = .photoLibrary
                    self.showImagePicker = true
                }
            } label: {
                profileImageStack
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $profileImage, sourceType: sourceType)
            }
            .onChange(of: profileImage) { _, newImage in
                if let image = newImage {
                    Task {
                        await profileViewModel.updateProfilePicture(with: image)
                    }
                }
            }
        } else {
            profileImageStack
        }
    }

    private var profileImageStack: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                if let image = profileViewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if let imageUrl = profileViewModel.avatarURL {
                    CachedAsyncImage(url: imageUrl)
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "person.fill")
                        .resizable()
                        .padding(15)
                        .foregroundColor(Color.themePrimary)
                        .background(Color.themeBackground.opacity(0.4))
                }
                if profileViewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.themeBackground.opacity(0.4))
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())

            if editableMode {
                Circle()
                    .stroke(Color.themeAccent, lineWidth: 2)
                    .frame(width: 80, height: 80)

                Image(systemName: "plus.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(Color.themeAccent, Color.themeElement)
                    .offset(x: -4, y: -4)
            }
        }
    }
}
