import SwiftUI

struct ProfilePictureView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel

    @State private var profileImage: UIImage?
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType =
        .photoLibrary

    var body: some View {
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
                            .foregroundColor(Color.nearWhite)
                            .background(Color.darkBackground.opacity(0.4))
                    }
                    if profileViewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.darkBackground.opacity(0.4))
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())

                Circle()
                    .stroke(Color.accentColor, lineWidth: 2)
                    .frame(width: 80, height: 80)

                Image(systemName: "plus.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(Color.babyBlue, Color.darkElement)
                    .offset(x: -4, y: -4)
            }
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
    }
}
