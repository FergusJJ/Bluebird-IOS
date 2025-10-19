import SwiftUI

struct ProfilePictureView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel

    let editableMode: Bool
    let isCurrentlyPlaying: Bool
    @State private var profileImage: UIImage?
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var rotationDegrees = 0.0
    @State private var glowOpacity = 0.3
    @State private var showExpandedImage = false
    @State private var showImageCropper = false
    @State private var imageToCrop: UIImage?

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
                    imageToCrop = image
                    profileImage = nil // Reset for next pick
                    showImagePicker = false // Dismiss picker first

                    // Delay cropper to let picker dismiss
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showImageCropper = true
                    }
                }
            }
            .fullScreenCover(isPresented: $showImageCropper) {
                if let imageToCrop = imageToCrop {
                    ImageCropperView(
                        image: imageToCrop,
                        onCrop: { croppedImage in
                            Task {
                                await profileViewModel.updateProfilePicture(with: croppedImage)
                                showImageCropper = false
                            }
                        },
                        onCancel: {
                            showImageCropper = false
                            self.imageToCrop = nil
                        }
                    )
                }
            }
        } else {
            profileImageStack
                .onTapGesture {
                    if profileViewModel.avatarURL != nil || profileViewModel.selectedImage != nil {
                        showExpandedImage = true
                    }
                }
                .sheet(isPresented: $showExpandedImage) {
                    ExpandedImageView(
                        image: profileViewModel.selectedImage,
                        imageUrl: profileViewModel.avatarURL
                    )
                }
        }
    }

    private var profileImageStack: some View {
        ZStack(alignment: .bottomTrailing) {
            profileImageContainer
        }
    }
    
    private var profileImageContainer: some View {
        Group {
            if isCurrentlyPlaying {
                animatedProfileImage
            } else {
                staticProfileImage
            }
        }
    }

    private var staticProfileImage: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(Color.themeAccent.opacity(0.2))
                .frame(width: 110, height: 110)
                .blur(radius: 10)

            // Main image
            ZStack {
                if let image = profileViewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else if let imageUrl = profileViewModel.avatarURL {
                    CachedAsyncImage(url: imageUrl, contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipped()
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.themeElement)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .padding(25)
                                .foregroundColor(Color.themePrimary)
                        )
                }

                if profileViewModel.isLoading {
                    ProgressView()
                        .frame(width: 100, height: 100)
                        .background(Color.themeBackground.opacity(0.4))
                        .clipShape(Circle())
                }
            }
            .overlay(
                Circle()
                    .stroke(Color.themeAccent.opacity(0.5), lineWidth: 3)
            )
        }
    }

    private var animatedProfileImage: some View {
        ZStack {
            glowingBackground
            rotatingGradientBorder
            profilePictureWithLoading
        }
        .onAppear {
            rotationDegrees = 360
            glowOpacity = 0.6
        }
    }

    private var glowingBackground: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.themeAccent.opacity(glowOpacity),
                        Color.clear,
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 50
                )
            )
            .frame(width: 100, height: 100)
            .blur(radius: 8)
            .animation(
                .easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true),
                value: glowOpacity
            )
    }

    private var rotatingGradientBorder: some View {
        Circle()
            .strokeBorder(
                AngularGradient(
                    colors: [
                        Color.themeAccent,
                        Color.themeAccent.opacity(0.3),
                        Color.themeAccent,
                    ],
                    center: .center,
                    startAngle: .degrees(0),
                    endAngle: .degrees(360)
                ),
                lineWidth: 3
            )
            .frame(width: 100, height: 100)
            .rotationEffect(.degrees(rotationDegrees))
            .animation(
                .linear(duration: 2.0)
                    .repeatForever(autoreverses: false),
                value: rotationDegrees
            )
    }

    private var profilePictureWithLoading: some View {
        ZStack {
            profileImageContent

            if profileViewModel.isLoading {
                loadingOverlay
            }
        }
        .frame(width: 100, height: 100)
        .clipShape(Circle())
    }

    private var profileImageContent: some View {
        Group {
            if let image = profileViewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
            } else if let imageUrl = profileViewModel.avatarURL {
                CachedAsyncImage(url: imageUrl, contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipped()
            } else {
                Circle()
                    .fill(Color.themeElement)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .padding(25)
                            .foregroundColor(Color.themePrimary)
                    )
            }
        }
    }

    private var loadingOverlay: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.themeBackground.opacity(0.4))
    }

    private var editModeOverlay: some View {
        Group {
            Circle()
                .stroke(Color.themeAccent, lineWidth: 2)
                .frame(width: 100, height: 100)

            Image(systemName: "plus.circle.fill")
                .font(.footnote)
                .foregroundStyle(Color.themeAccent, Color.themeElement)
                .offset(x: -4, y: -4)
        }
    }
}
