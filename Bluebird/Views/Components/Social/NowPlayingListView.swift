import SwiftUI

struct NowPlayingListView: View {
    @EnvironmentObject var socialViewModel: SocialViewModel

    @Binding var selectedSong: SongDetail?
    @Binding var selectedUser: UserProfile?

    var body: some View {
        List {
            ForEach(
                Array(socialViewModel.friendsCurrentlyPlaying).sorted(by: {
                    $0.key < $1.key
                }),
                id: \.key
            ) { _, trackAndUser in
                FriendSongRowView(
                    song: trackAndUser.track,
                    username: trackAndUser.profile.username,
                    profilePictureURL: !trackAndUser.profile.avatar_url.isEmpty
                        ? URL(string: trackAndUser.profile.avatar_url)
                        : nil,
                    onSongTap: {
                        selectedSong = trackAndUser.track
                    },
                    onProfileTap: {
                        selectedUser = trackAndUser.profile
                    }
                )
                .listRowInsets(EdgeInsets())
            }
        }
        .listRowSpacing(8)
        .scrollContentBackground(.hidden)
        .background(Color.themeBackground)
        .navigationDestination(item: $selectedSong) { song in
            SongDetailView(
                trackID: song.track_id,
                imageURL: song.album_image_url,
                name: song.name
            )
        }
        .navigationDestination(item: $selectedUser) { profile in
            UserProfileView(userProfile: profile)
        }
        .refreshable {
            await socialViewModel.fetchFriendsCurrentlyPlaying()
        }
    }
}
