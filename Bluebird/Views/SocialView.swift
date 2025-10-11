import SwiftUI

struct SocialView: View {
    @EnvironmentObject var socialViewModel: SocialViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @State private var isSearching = false

    @State private var selectedSong: SongDetail?
    @State private var selectedUserId: String?

    var body: some View {
        VStack(spacing: 0) {
            if isSearching {
                SearchbarView(isSearching: $isSearching)
                    .padding(.top, 10)
                    .transition(.move(edge: .top))
                    .zIndex(2)
            }

            ZStack {
                friendCurrentlyListeningList
                /*
                 if isSearching {
                     // if searching and there are results, show list
                 } else {
                     // otherwise show feed
                     friendCurrentlyListeningList
                 }
                 if isSearching {
                     // if searching an there are no results, allow clicking out of
                     // the search view
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
                 }*/
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

    private var friendCurrentlyListeningList: some View {
        List {
            ForEach(
                Array(socialViewModel.friendsCurrentlyPlaying).sorted(by: {
                    $0.key < $1.key
                }),
                id: \.key
            ) { userId, song in
                // I want to use navigation link here, but depending on whether the song or
                // friend pfp is clicked it should go elsewhere
                FriendSongRowView(
                    song: song,
                    username: "fergus",
                    profilePictureURL: profileViewModel.avatarURL,
                    onSongTap: {
                        selectedSong = song
                    },
                    onProfileTap: {
                        selectedUserId = userId
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
        .navigationDestination(item: $selectedUserId) { _ in
            ProfileView(isCurrentUser: false)
        }
        .refreshable {
            await socialViewModel.fetchFriendsCurrentlyPlaying()
        }
    }
}
