import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var socialViewModel: SocialViewModel
    let userProfile: UserProfile

    @State private var selectedTrack: SongDetail?
    @State private var selectedAlbum: AlbumDetail?
    @State private var selectedArtist: ArtistDetail?
    @State private var showRemoveFriendAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                userHeadlineView()
                    .padding(.bottom, 20)

                if let detail = socialViewModel.currentUserProfile {
                    if detail.is_private && detail.friendship_status != .friends {
                        privateProfileView()
                    } else {
                        VStack(spacing: 24) {
                            if !detail.pinned_tracks.isEmpty {
                                pinnedTracksView(tracks: detail.pinned_tracks)
                            }

                            if !detail.pinned_albums.isEmpty {
                                pinnedAlbumsView(albums: detail.pinned_albums)
                            }

                            if !detail.pinned_artists.isEmpty {
                                pinnedArtistsView(
                                    artists: detail.pinned_artists
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
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
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    await socialViewModel.fetchUserProfile(
                        userId: userProfile.user_id,
                        forceRefresh: false
                    )
                }
            }
        }
        .alert("Remove Friend", isPresented: $showRemoveFriendAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                Task {
                    await removeFriend(userId: userProfile.user_id)
                }
            }
        } message: {
            Text(
                "Are you sure you want to remove \(userProfile.username)? You will have to request them again."
            )
        }
    }

    @ViewBuilder
    fileprivate func userHeadlineView() -> some View {
        VStack(alignment: .center, spacing: 16) {
            // Profile image and username section
            VStack(spacing: 12) {
                profileImageContainer

                VStack(spacing: 4) {
                    Text(userProfile.username)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.themePrimary)

                    if !userProfile.bio.isEmpty {
                        Text(userProfile.bio)
                            .font(.subheadline)
                            .foregroundColor(Color.themeSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 20)
                    }
                }
            }

            if let detail = socialViewModel.currentUserProfile {
                // Stats
                if !detail.is_private || detail.friendship_status == .friends {
                    HeadlineStatsView(
                        totalMinutesListened: detail.total_minutes_listened
                            ?? 0,
                        totalPlays: detail.total_plays ?? 0,
                        totalUniqueArtists: detail.total_unique_artists ?? 0,
                        friendCount: detail.friend_count
                    )
                    .padding(.horizontal)
                }

                // Friend action button
                friendshipButton(status: detail.friendship_status)
                    .padding(.horizontal)
            }
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
    }

    @ViewBuilder
    fileprivate var profileImageContainer: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(Color.themeAccent.opacity(0.2))
                .frame(width: 110, height: 110)
                .blur(radius: 10)

            // Main image
            Group {
                if userProfile.avatar_url.isEmpty {
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
                } else {
                    CachedAsyncImage(url: URL(string: userProfile.avatar_url)!)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                }
            }
            .overlay(
                Circle()
                    .stroke(Color.themeAccent.opacity(0.5), lineWidth: 3)
            )
        }
    }

    @ViewBuilder
    fileprivate func friendshipButton(status: FriendshipStatus) -> some View {
        switch status {
        case .friends:
            Button(action: {
                showRemoveFriendAlert = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Friends")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color.themePrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.themeElement)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.themeAccent.opacity(0.3), lineWidth: 1)
                )
            }
        case .outgoing:
            Button(action: {
                Task {
                    await removeFriend(userId: userProfile.user_id)
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                    Text("Request Pending")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color.themeSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.themeElement)
                .cornerRadius(12)
            }
        case .incoming:
            HStack(spacing: 12) {
                Button(action: {
                    Task {
                        await acceptFriendRequest(userId: userProfile.user_id)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                        Text("Accept")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.themeAccent)
                    .cornerRadius(12)
                }

                Button(action: {
                    Task {
                        await denyFriendRequest(userId: userProfile.user_id)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark")
                        Text("Decline")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.themePrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.themeElement)
                    .cornerRadius(12)
                }
            }
        case .none:
            Button(action: {
                Task {
                    await sendFriendRequest(userId: userProfile.user_id)
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                    Text("Add Friend")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [
                            Color.themeAccent, Color.themeAccent.opacity(0.8),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(
                    color: Color.themeAccent.opacity(0.3),
                    radius: 8,
                    x: 0,
                    y: 4
                )
            }
        }
    }

    @ViewBuilder
    fileprivate func privateProfileView() -> some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.themeElement)
                        .frame(width: 80, height: 80)

                    Image(systemName: "lock.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color.themeSecondary)
                }

                Text("This Account is Private")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.themePrimary)

                Text(
                    "You need to be friends with this user to see their profile"
                )
                .font(.subheadline)
                .foregroundColor(Color.themeSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    @ViewBuilder
    fileprivate func pinnedTracksView(tracks: [SongDetail]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "music.note")
                    .foregroundColor(Color.themeAccent)
                    .font(.headline)
                Text("Pinned Tracks")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.themePrimary)
                Spacer()
            }

            HorizontalScrollSection.tracks(
                title: "",
                items: tracks
            ) { track in
                selectedTrack = track
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "square.stack")
                    .foregroundColor(Color.themeAccent)
                    .font(.headline)
                Text("Pinned Albums")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.themePrimary)
                Spacer()
            }

            HorizontalScrollSection.albums(
                title: "",
                items: albums
            ) { album in
                selectedAlbum = album
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.wave.2")
                    .foregroundColor(Color.themeAccent)
                    .font(.headline)
                Text("Pinned Artists")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.themePrimary)
                Spacer()
            }

            HorizontalScrollSection.artists(
                title: "",
                items: artists
            ) { artist in
                selectedArtist = artist
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

    private func removeFriend(userId: String) async {
        print("removeFriend(userId: \(userId)")
        await socialViewModel.removeFriend(friend: userId)
    }
}
