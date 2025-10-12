import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var socialViewModel: SocialViewModel
    let userProfile: UserProfile

    @State private var selectedTrack: SongDetail?
    @State private var selectedAlbum: AlbumDetail?
    @State private var selectedArtist: ArtistDetail?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                userHeadlineView()

                if let detail = socialViewModel.currentUserProfile {
                    if detail.is_private && detail.friendship_status != .friends {
                        privateProfileView()
                    } else {
                        Divider()
                        VStack {
                            pinnedTracksView(tracks: detail.pinned_tracks)
                            Divider()
                            pinnedAlbumsView(albums: detail.pinned_albums)
                            Divider()
                            pinnedArtistsView(artists: detail.pinned_artists)
                            Divider()
                        }
                        .padding()
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                } else {
                    ProgressView()
                        .padding()
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.themeBackground.ignoresSafeArea(edges: .all))
        .navigationTitle(userProfile.username)
        .navigationBarTitleDisplayMode(.inline)
        .applyDefaultTabBarStyling()
        .refreshable {
            await socialViewModel.fetchUserProfile(
                userId: userProfile.user_id,
                forceRefresh: true
            )
        }
        .task {
            await socialViewModel.fetchUserProfile(
                userId: userProfile.user_id,
                forceRefresh: false
            )
        }
    }

    @ViewBuilder
    fileprivate func userHeadlineView() -> some View {
        VStack(alignment: .center, spacing: 15) {
            HStack(alignment: .top, spacing: 15) {
                profileImageContainer
                VStack(alignment: .leading, spacing: 8) {
                    Text(userProfile.username)
                        .font(.headline)
                        .foregroundStyle(Color.themePrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if !userProfile.bio.isEmpty {
                        Text(userProfile.bio)
                            .font(.subheadline)
                            .foregroundColor(Color.themePrimary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let detail = socialViewModel.currentUserProfile {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.caption)
                            Text("\(detail.friend_count) friends")
                                .font(.caption)
                        }
                        .foregroundColor(Color.themeSecondary)
                    }
                }
                .layoutPriority(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let detail = socialViewModel.currentUserProfile {
                // Show stats if not private or if friends
                if !detail.is_private || detail.friendship_status == .friends {
                    HeadlineStatsView(
                        totalMinutesListened: detail.total_minutes_listened
                            ?? 0,
                        totalPlays: detail.total_plays ?? 0,
                        totalUniqueArtists: detail.total_unique_artists ?? 0
                    )
                }

                // Friend request button
                friendshipButton(status: detail.friendship_status)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    fileprivate var profileImageContainer: some View {
        Group {
            if userProfile.avatar_url.isEmpty {
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(15)
                    .foregroundColor(Color.themePrimary)
                    .background(Color.themeBackground.opacity(0.4))
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
            } else {
                CachedAsyncImage(url: URL(string: userProfile.avatar_url)!)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
            }
        }
    }

    @ViewBuilder
    fileprivate func friendshipButton(status: FriendshipStatus) -> some View {
        switch status {
        case .friends: // TODO: - needs to issue remvoe friend request
            Button()
            EmptyView()
        case .outgoing:
            // TODO: - should delete outgoing request
            Button(action: {}) {
                HStack {
                    Image(systemName: "checkmark")
                    Text("Friend Request Sent")
                }
                .font(.subheadline)
                .foregroundColor(Color.themeSecondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.themeElement)
                .cornerRadius(20)
            }
            .disabled(true)
        case .incoming:
            HStack(spacing: 12) {
                Button(action: {
                    Task {
                        await acceptFriendRequest(userId: userProfile.user_id)
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Accept")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.themeAccent)
                    .cornerRadius(20)
                }

                Button(action: {
                    Task {
                        await denyFriendRequest(userId: userProfile.user_id)
                    }
                }) {
                    HStack {
                        Image(systemName: "xmark")
                        Text("Decline")
                    }
                    .font(.subheadline)
                    .foregroundColor(Color.themePrimary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.themeElement)
                    .cornerRadius(20)
                }
            }
        case .none:
            Button(action: {
                Task {
                    await sendFriendRequest(userId: userProfile.user_id)
                }
            }) {
                HStack {
                    Image(systemName: "person.badge.plus")
                    Text("Add Friend")
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.themeAccent)
                .cornerRadius(20)
            }
        }
    }

    @ViewBuilder
    fileprivate func privateProfileView() -> some View {
        VStack(spacing: 20) {
            Divider()
            VStack(spacing: 12) {
                Image(systemName: "lock.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color.themeSecondary)

                Text("This Account is Private")
                    .font(.headline)
                    .foregroundColor(Color.themePrimary)

                Text(
                    "You need to be friends with this user to see their profile"
                )
                .font(.subheadline)
                .foregroundColor(Color.themeSecondary)
                .multilineTextAlignment(.center)
            }
            .padding(40)
        }
    }

    @ViewBuilder
    fileprivate func pinnedTracksView(tracks: [SongDetail]) -> some View {
        VStack {
            if tracks.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Pinned Tracks")
                        .foregroundStyle(Color.themePrimary)
                        .font(.subheadline)

                    Text("Nothing to see here.")
                        .foregroundStyle(Color.themePrimary.opacity(0.6))
                        .font(.caption)
                        .padding(.vertical, 10)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            } else {
                HorizontalScrollSection.tracks(
                    title: "Pinned Tracks",
                    items: tracks
                ) { track in
                    selectedTrack = track
                }
                .padding(.horizontal)
            }
        }
        .navigationDestination(item: $selectedTrack) { track in
            SongDetailView(
                trackID: track.track_id,
                imageURL: track.album_image_url,
                name: track.name
            )
        }
    }

    @ViewBuilder
    fileprivate func pinnedAlbumsView(albums: [AlbumDetail]) -> some View {
        VStack {
            if albums.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Pinned Albums")
                        .foregroundStyle(Color.themePrimary)
                        .font(.subheadline)

                    Text("Nothing to see here.")
                        .foregroundStyle(Color.themePrimary.opacity(0.6))
                        .font(.caption)
                        .padding(.vertical, 10)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            } else {
                HorizontalScrollSection.albums(
                    title: "Pinned Albums",
                    items: albums
                ) { album in
                    selectedAlbum = album
                }
                .padding(.horizontal)
            }
        }
        .navigationDestination(item: $selectedAlbum) { album in
            AlbumDetailView(
                albumID: album.album_id,
                albumName: album.name,
                albumImageURL: album.image_url
            )
        }
    }

    @ViewBuilder
    fileprivate func pinnedArtistsView(artists: [ArtistDetail]) -> some View {
        VStack {
            if artists.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Pinned Artists")
                        .foregroundStyle(Color.themePrimary)
                        .font(.subheadline)

                    Text("Nothing to see here.")
                        .foregroundStyle(Color.themePrimary.opacity(0.6))
                        .font(.caption)
                        .padding(.vertical, 10)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            } else {
                HorizontalScrollSection.artists(
                    title: "Pinned Artists",
                    items: artists
                ) { artist in
                    selectedArtist = artist
                }
                .padding(.horizontal)
            }
        }
        .navigationDestination(item: $selectedArtist) { artist in
            ArtistDetailView(
                artist: SongDetailArtist(
                    id: artist.artist_id,
                    image_url: artist.spotify_uri,
                    name: artist.name
                )
            )
        }
    }

    // MARK: - API Calls

    private func sendFriendRequest(userId: String) async {
        print("sendFriendRequest(userId: \(userId))")
        await socialViewModel.sendFriendRequest(to: userId)
    }

    private func acceptFriendRequest(userId: String) async {
        print("acceptFriendRequest(userId: \(userId))")
        await socialViewModel.respondToFriendRequests(to: userId, accept: true)
    }

    private func denyFriendRequest(userId: String) async {
        print("denyFriendRequest(userId: \(userId))")
        await socialViewModel.respondToFriendRequests(to: userId, accept: false)
    }
}
