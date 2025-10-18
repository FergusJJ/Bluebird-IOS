import SwiftUI

struct SocialFeedListView: View {
    @EnvironmentObject var socialViewModel: SocialViewModel

    @Binding var selectedSong: SongDetail?
    @Binding var selectedAlbum: AlbumDetail?
    @Binding var selectedArtist: ArtistDetail?
    @Binding var selectedUser: UserProfile?
    @Binding var postToDelete: FeedPost?
    @Binding var showDeletePostModal: Bool

    let currentUserID: String?
    let onFindFriends: () -> Void

    var body: some View {
        Group {
            if socialViewModel.feedPosts.isEmpty && socialViewModel.friendsCurrentlyPlaying.isEmpty && !socialViewModel.isLoadingFeed {
                EmptyFeedStateView(onFindFriends: onFindFriends)
            } else {
                feedList
            }
        }
        .navigationDestination(item: $selectedSong) { song in
            SongDetailView(
                trackID: song.track_id,
                imageURL: song.album_image_url,
                name: song.name
            )
        }
        .navigationDestination(item: $selectedAlbum) { album in
            AlbumDetailView(
                albumID: album.album_id,
                albumName: album.name,
                albumImageURL: album.image_url
            )
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
        .navigationDestination(item: $selectedUser) { profile in
            UserProfileView(userProfile: profile)
        }
        .refreshable {
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    await socialViewModel.fetchFeed(forceRefresh: true)
                }
                group.addTask {
                    await socialViewModel.fetchFriendsCurrentlyPlaying()
                }
            }
        }
    }

    private var feedList: some View {
        List {
            // Currently Playing Section
            let _ = print("DEBUG: friendsCurrentlyPlaying count = \(socialViewModel.friendsCurrentlyPlaying.count)")
            if !socialViewModel.friendsCurrentlyPlaying.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "waveform")
                            .font(.headline)
                            .foregroundColor(Color.themeAccent)
                        Text("Friends Listening Now")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.themePrimary)
                    }

                    ForEach(
                        Array(socialViewModel.friendsCurrentlyPlaying).sorted(by: {
                            $0.key < $1.key
                        }).prefix(3),
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
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16))
            }

            // Feed Posts
            ForEach(socialViewModel.feedPosts) { feedPost in
                FeedPostRowView(
                    feedPost: feedPost,
                    currentUserID: currentUserID,
                    onEntityTap: {
                        handleFeedEntityTap(feedPost: feedPost)
                    },
                    onProfileTap: {
                        selectedUser = feedPost.post.author
                    },
                    onDeleteTap: {
                        postToDelete = feedPost.post
                        showDeletePostModal = true
                    }
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            if socialViewModel.feedHasMore {
                Button(action: {
                    Task {
                        await socialViewModel.loadMoreFeedPosts()
                    }
                }) {
                    if socialViewModel.isLoadingFeed {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        Text("Load More")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.themeAccent)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
        }
        .listRowSpacing(8)
        .scrollContentBackground(.hidden)
        .background(Color.themeBackground)
    }

    private func handleFeedEntityTap(feedPost: FeedPostItem) {
        if let track = feedPost.track_detail {
            selectedSong = track
        } else if let album = feedPost.album_detail {
            selectedAlbum = album
        } else if let artist = feedPost.artist_detail {
            selectedArtist = artist
        }
    }
}
