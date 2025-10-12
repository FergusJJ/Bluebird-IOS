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
            if isCurrentlyPlaying && !editableMode {
                animatedProfileImage
            } else {
                staticProfileImage
            }

            if editableMode {
                editModeOverlay
            }
        }
    }

    private var staticProfileImage: some View {
        ZStack {
            profileImageContent

            if profileViewModel.isLoading {
                loadingOverlay
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(Circle())
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
            .frame(width: 80, height: 80)
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
        .frame(width: 76, height: 76)
        .clipShape(Circle())
    }

    private var profileImageContent: some View {
        Group {
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
                .frame(width: 80, height: 80)

            Image(systemName: "plus.circle.fill")
                .font(.footnote)
                .foregroundStyle(Color.themeAccent, Color.themeElement)
                .offset(x: -4, y: -4)
        }
    }
}
