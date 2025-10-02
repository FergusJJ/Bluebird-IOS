import SwiftUI

struct ProfileHeadlineView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel

    var body: some View {
        VStack(alignment: .center, spacing: 15) {
            HStack(spacing: 15) {
                ProfilePictureView(editableMode: false)
                VStack(spacing: 15) {
                    Text(profileViewModel.username)
                        .font(.headline)
                        .foregroundStyle(Color.nearWhite)

                    Text(profileViewModel.bio.isEmpty ? "No bio yet." : profileViewModel.bio)
                        .font(.subheadline)
                        .foregroundColor(profileViewModel.bio.isEmpty ? Color.lightGray : Color.nearWhite)
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
                .foregroundStyle(Color.gray)
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
