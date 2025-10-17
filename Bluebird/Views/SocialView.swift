import SwiftUI

struct SocialView: View {
    @EnvironmentObject var socialViewModel: SocialViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var searchViewModel:
        GenericSearchViewModel<UserProfile, SearchUserResult>

    @State private var isSearching = false
    @State private var selectedView: SocialViewType = .feed

    @State private var selectedSong: SongDetail?
    @State private var selectedAlbum: AlbumDetail?
    @State private var selectedArtist: ArtistDetail?
    @State private var selectedUser: UserProfile?
    @State private var showDeletePostModal = false
    @State private var postToDelete: FeedPost?

    enum SocialViewType {
        case feed
        case currentlyPlaying
    }

    var body: some View {
        VStack(spacing: 0) {
            if isSearching {
                SearchbarView<UserProfile, SearchUserResult>(
                    isSearching: $isSearching,
                    placeholderText: "Search users"
                )
                .padding(.top, 10)
                .transition(.move(edge: .top))
                .zIndex(2)
            }

            // View toggle (only show when not searching)
            if !isSearching {
                viewToggle
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
            }

            ZStack {
                if isSearching && !searchViewModel.searchResults.isEmpty {
                    searchResultsList
                } else if isSearching {
                    Color.clear
                        .contentShape(Rectangle())
                        .ignoresSafeArea()
                        .onTapGesture {
                            isSearching = false
                            DispatchQueue.main.async {
                                UIApplication.shared.sendAction(
                                    #selector(UIResponder.resignFirstResponder),
                                    to: nil,
                                    from: nil,
                                    for: nil
                                )
                            }
                        }
                        .zIndex(1)
                } else {
                    if selectedView == .feed {
                        feedList
                    } else {
                        friendCurrentlyListeningList
                    }
                }
            }
        }
        .task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    await socialViewModel.fetchFriendsCurrentlyPlaying()
                }
                group.addTask {
                    await socialViewModel.fetchFeed()
                }
            }
        }
        .sheet(isPresented: $showDeletePostModal) {
            if let post = postToDelete {
                DeletePostConfirmationModal(
                    post: post,
                    onConfirm: {
                        Task {
                            let success = await socialViewModel.deletePost(postID: post.post_id)
                            if success {
                                showDeletePostModal = false
                                postToDelete = nil
                            }
                        }
                    },
                    onCancel: {
                        showDeletePostModal = false
                        postToDelete = nil
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.themeBackground.ignoresSafeArea())
        .navigationTitle("Feed")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Image(systemName: "person.crop.badge.magnifyingglass.fill")
                    .foregroundColor(Color.themePrimary)
                    .onTapGesture {
                        withAnimation { isSearching.toggle() }
                    }
            }
        }
        .applyDefaultTabBarStyling()
    }

    private var searchResultsList: some View {
        List {
            ForEach(searchViewModel.searchResults) { result in
                NavigationLink(destination: destinationView(for: result)) {
                    ClickableUserRowView(user: result)
                }
                .listRowBackground(Color.themeElement)
            }
            if searchViewModel.isSearching {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.themeBackground)
    }

    private var friendCurrentlyListeningList: some View {
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

    private var viewToggle: some View {
        HStack(spacing: 0) {
            Button(action: { selectedView = .feed }) {
                Text("Feed")
                    .font(.subheadline)
                    .fontWeight(selectedView == .feed ? .semibold : .regular)
                    .foregroundColor(selectedView == .feed ? Color.themePrimary : Color.themeSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        selectedView == .feed ? Color.themeElement : Color.clear
                    )
            }
            .buttonStyle(PlainButtonStyle())

            Divider()
                .background(Color.themeSecondary.opacity(0.3))

            Button(action: { selectedView = .currentlyPlaying }) {
                Text("Now Playing")
                    .font(.subheadline)
                    .fontWeight(selectedView == .currentlyPlaying ? .semibold : .regular)
                    .foregroundColor(selectedView == .currentlyPlaying ? Color.themePrimary : Color.themeSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        selectedView == .currentlyPlaying ? Color.themeElement : Color.clear
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(height: 36)
        .background(Color.themeBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.themeSecondary.opacity(0.2), lineWidth: 1)
        )
    }

    private var feedList: some View {
        List {
            ForEach(socialViewModel.feedPosts) { feedPost in
                FeedPostRowView(
                    feedPost: feedPost,
                    currentUserID: CacheManager.shared.getCurrentUserId(),
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
            await socialViewModel.fetchFeed(forceRefresh: true)
        }
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

    private func destinationView(for profile: UserProfile) -> some View {
        UserProfileView(userProfile: profile)
    }
}
