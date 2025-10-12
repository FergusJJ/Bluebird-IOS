import SwiftUI

struct SocialView: View {
    @EnvironmentObject var socialViewModel: SocialViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var searchViewModel:
        GenericSearchViewModel<UserProfile, SearchUserResult>

    @State private var isSearching = false

    @State private var selectedSong: SongDetail?
    @State private var selectedUser: UserProfile?

    // current idea for social view
    /*
     if have a pinned user, always show whatever they're playing at top of feed
     will either do:
        -have switcher between feed, so reposts, etc. and the current activity.
        so only don't mix together, either on friend activity or friend feed
        -combine both? This would just stick all the activity at the top?
        or could have a horizontal scroll view at the top showing activity (kinda like stories on tiktok showign in your dms)
        if you click on one it expands into the row like it currently does, and then you maybe have to go back a page to get rid?

     probably goinf to have to draw these up

     Priority list:
     - New stuff
        - add private/public toggle to profiles
        - add friend requests, show number of friends on profile
        |-> pinning should be fairly easy after that
        |-> will be ready to actually send friends into the get currently listening call then
        - add reposts
        |-> likes, comments
        |-> show on profile
        - feed, already have function supporting pagination, so use this
     - Improvements
        - fix search song bg on light mode
        - cache in swiftstorage: feed, history, profile info
        - finish the newly discovered (pretty much just need to order)
        - liquid glass stuff to tab bar, search, floating buttons
     - Possible features
        - animate user profile picture when listening to a song

     */
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

            ZStack {
                if isSearching && !searchViewModel.searchResults.isEmpty {
                    searchResultsList
                } else {
                    friendCurrentlyListeningList
                }
                if isSearching && searchViewModel.searchResults.isEmpty {
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
                }
            }
        }
        .task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    await socialViewModel.fetchFriendsCurrentlyPlaying()
                }
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
                // I want to use navigation link here, but depending on whether the song or
                // friend pfp is clicked it should go elsewhere
                FriendSongRowView(
                    song: trackAndUser.track,
                    username: "fergus",
                    profilePictureURL: profileViewModel.avatarURL,
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
            SongDetailView(song: song)
        }
        .navigationDestination(item: $selectedUser) { profile in
            UserProfileView(userProfile: profile)
        }
        .refreshable {
            await socialViewModel.fetchFriendsCurrentlyPlaying()
        }
    }

    private func destinationView(for profile: UserProfile) -> some View {
        UserProfileView(userProfile: profile)
    }
}
