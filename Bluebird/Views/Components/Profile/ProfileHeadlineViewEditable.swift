import SwiftUI

struct ProfileHeadlineViewEditable: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel

    let editableMode: Bool
    @State private var isEditing = false
    @State private var editingBio = ""

    var body: some View {
        VStack(alignment: .center, spacing: 15) {
            HStack(spacing: 15) {
                ProfilePictureView(editableMode: editableMode) // You could also make this tappable to change photo
                VStack(spacing: 15) {
                    Text(profileViewModel.username)
                        .font(.headline)
                        .foregroundStyle(Color.themePrimary)

                    if isEditing {
                        VStack(alignment: .trailing, spacing: 10) {
                            TextEditor(text: $editingBio)
                                .font(.subheadline)
                                .scrollContentBackground(.hidden)
                                .foregroundColor(Color.themePrimary)
                                .frame(minHeight: 50, maxHeight: 100)
                                .padding(5)
                                .background(Color.themeElement)
                                .cornerRadius(10)
                                .tint(Color.accentColor)

                            HStack(spacing: 20) {
                                Button("Discard") {
                                    withAnimation { isEditing = false }
                                }
                                .foregroundColor(Color.themeSecondary)

                                Button("Save") {
                                    Task {
                                        let success = await profileViewModel.updateUserBio(with: editingBio)
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

                    } else {
                        Text(profileViewModel.bio.isEmpty ? "Tap to add a bio" : profileViewModel.bio)
                            .font(.subheadline)
                            .foregroundColor(profileViewModel.bio.isEmpty ? Color.themeSecondary : Color.themePrimary)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 5)
                            .onTapGesture {
                                if editableMode {
                                    editingBio = profileViewModel.bio
                                    withAnimation { isEditing = true }
                                }
                            }
                    }
                }
            }

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
