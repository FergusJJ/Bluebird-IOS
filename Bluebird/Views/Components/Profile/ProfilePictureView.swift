import SwiftUI

struct ProfilePictureView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel

    let editableMode: Bool
    let isCurrentlyPlaying: Bool
    @State private var profileImage: UIImage?
    @State private var showImagePicker = false
    @State private var showCropView = false
    var body: some View {
        //image picker stuff
        if editableMode {
            Menu {
                Button(
                    "Choose from liibrary",
                    systemImage: "photo.on.rectangle"
                ) {
                    self.showImagePicker = true
                }
            } label: {
                profilePictureView()
            }.sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $profileImage)
            }.onChange(of: profileImage) { _, newImage in
                showImagePicker = false
                if newImage != nil {
                    showCropView = true
                }
            }
            .fullScreenCover(isPresented: $showCropView) {
                if let image = profileImage {
                    ImageCropperView(
                        image: image,
                        onCancel: {
                            showCropView = false
                        },
                        onCrop: { img in
                            Task {
                                let success =
                                    await profileViewModel.updateProfilePicture(
                                        with: img
                                    )
                                if success {
                                    profileImage = nil
                                    
                                }
                            }
                            showCropView = false
                        }
                    )
                }
            }
        } else {
            profilePictureView()
        }
    }

    @ViewBuilder
    fileprivate func profilePictureView() -> some View {
        if let profilePicture = profileImage {
            Image(uiImage: profilePicture)
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .aspectRatio(contentMode: .fit)
        } else if let profilePictureUrl = profileViewModel.avatarURL {
            CachedAsyncImage(url: profilePictureUrl, contentMode: .fit)
                .frame(width: 100, height: 100)
                .clipShape(Circle())
        } else {
            // placeholder
            Circle()
                .fill(Color.themeElement)
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "person.fill")
                )
        }
        if profileViewModel.isLoading {
            ProgressView()
                .frame(width: 100, height: 100)
                .clipShape(Circle())
        }
    }
}
