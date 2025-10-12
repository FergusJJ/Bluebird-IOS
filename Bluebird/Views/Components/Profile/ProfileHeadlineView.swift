import SwiftUI

struct ProfileHeadlineView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel

    var body: some View {
        VStack(alignment: .center, spacing: 15) {
            HStack(spacing: 15) {
                ProfilePictureView(
                    editableMode: false,
                    isCurrentlyPlaying: profileViewModel.isCurrentlyPlaying()
                )
                VStack(spacing: 15) {
                    Text(profileViewModel.username)
                        .font(.headline)
                        .foregroundStyle(Color.themePrimary)

                    Text(profileViewModel.bio)
                        .font(.subheadline)
                        .foregroundColor(
                            profileViewModel.bio.isEmpty
                                ? Color.themeSecondary : Color.themePrimary
                        )
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 5)
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
