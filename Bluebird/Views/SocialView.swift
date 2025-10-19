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
    @State private var postToDelete: IdentifiableString?

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

            if !isSearching {
                SocialViewToggle(selectedView: $selectedView)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
            }

            ZStack {
                if isSearching && !searchViewModel.searchResults.isEmpty {
                    UserSearchResultsList()
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
                        SocialFeedListView(
                            selectedSong: $selectedSong,
                            selectedAlbum: $selectedAlbum,
                            selectedArtist: $selectedArtist,
                            selectedUser: $selectedUser,
                            postToDelete: $postToDelete,
                            currentUserID: CacheManager.shared.getCurrentUserId(),
                            onFindFriends: {
                                withAnimation {
                                    isSearching = true
                                }
                            }
                        )
                    } else {
                        TrendingListView(
                            selectedSong: $selectedSong
                        )
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
                    await socialViewModel.fetchUnifiedFeed()
                }
                group.addTask {
                    await socialViewModel.fetchTrendingTracks()
                }
            }
        }
        .sheet(item: $postToDelete) { identifiablePost in
            DeletePostConfirmationModal(
                postID: identifiablePost.value,
                onConfirm: {
                    Task {
                        let success = await socialViewModel.deletePost(postID: identifiablePost.value)
                        if success {
                            postToDelete = nil
                        }
                    }
                },
                onCancel: {
                    postToDelete = nil
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
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
}
