import SwiftUI

struct ProfileHeadlineViewEditable: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel

    let editableMode: Bool
    @State private var isEditing = false
    @State private var editingBio = ""

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            // Profile image and username section
            VStack(spacing: 12) {
                profileImageContainer

                VStack(spacing: 4) {
                    Text(profileViewModel.username)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.themePrimary)

                    if isEditing {
                        VStack(spacing: 10) {
                            TextEditor(text: $editingBio)
                                .font(.subheadline)
                                .scrollContentBackground(.hidden)
                                .foregroundColor(Color.themePrimary)
                                .frame(minHeight: 50, maxHeight: 100)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(6)
                                .background(Color.themeElement)
                                .cornerRadius(10)
                                .tint(Color.themeAccent)

                            HStack(spacing: 20) {
                                Button("Discard") {
                                    withAnimation { isEditing = false }
                                }
                                .foregroundColor(Color.themeSecondary)

                                Button("Save") {
                                    Task {
                                        let success =
                                            await profileViewModel.updateUserBio(
                                                with: editingBio
                                            )
                                        if success {
                                            withAnimation { isEditing = false }
                                        }
                                    }
                                }
                                .foregroundColor(Color.themeAccent)
                                .bold()
                            }
                        }
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    } else {
                        Text(
                            profileViewModel.bio.isEmpty && editableMode
                                ? "Tap to add a bio" : profileViewModel.bio
                        )
                        .font(.subheadline)
                        .foregroundColor(
                            profileViewModel.bio.isEmpty
                                ? Color.themeSecondary : Color.themePrimary
                        )
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 20)
                        .onTapGesture {
                            if editableMode {
                                editingBio = profileViewModel.bio
                                withAnimation { isEditing = true }
                            }
                        }
                    }
                }
            }

            // Stats
            HeadlineStatsView(
                totalMinutesListened: profileViewModel.totalMinutesListened,
                totalPlays: profileViewModel.totalPlays,
                totalUniqueArtists: profileViewModel.totalUniqueArtists,
                friendCount: 1  // TODO: Get own friends on load
            )
            .padding(.horizontal)
        }
        .padding(.vertical, 20)
        .background(
            LinearGradient(
                colors: [
                    Color.themeElement.opacity(0.3),
                    Color.themeBackground,
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onAppear {
            Task {
                await profileViewModel.loadProfile()
                await profileViewModel.loadHeadlineStats()
            }
        }
    }

    @ViewBuilder
    fileprivate var profileImageContainer: some View {
        ProfilePictureView(editableMode: editableMode, isCurrentlyPlaying: profileViewModel.isCurrentlyPlaying())
    }
}
