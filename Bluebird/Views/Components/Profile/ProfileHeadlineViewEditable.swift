import SwiftUI

struct ProfileHeadlineViewEditable: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel

    let editableMode: Bool
    @State private var isEditing = false
    @State private var editingBio = ""

    var body: some View {
        VStack(alignment: .center, spacing: 15) {
            HStack(alignment: .top, spacing: 15) {
                ProfilePictureView(editableMode: editableMode, isCurrentlyPlaying: profileViewModel.isCurrentlyPlaying())
                    .frame(width: 80, height: 80)
                    .alignmentGuide(.top) { d in d[.top] }
                VStack(alignment: .leading, spacing: 12) {
                    Text(profileViewModel.username)
                        .font(.headline)
                        .foregroundStyle(Color.themePrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if isEditing {
                        VStack(alignment: .leading, spacing: 10) {
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
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .frame(maxWidth: .infinity, alignment: .leading)

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
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 5)
                        .onTapGesture {
                            if editableMode {
                                editingBio = profileViewModel.bio
                                withAnimation { isEditing = true }
                            }
                        }
                    }
                }
                .layoutPriority(1)
            }
            Spacer()

            HeadlineStatsView(
                totalMinutesListened: profileViewModel.totalMinutesListened,
                totalPlays: profileViewModel.totalPlays,
                totalUniqueArtists: profileViewModel.totalUniqueArtists
            )

            Spacer()
            Text(profileViewModel.getCurrentlyPlayingHeadline())
                .font(.subheadline)
                .foregroundStyle(Color.themeSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .center)
        .onAppear {
            Task {
                await profileViewModel.loadProfile()
                await profileViewModel.loadHeadlineStats()
            }
        }
    }
}
