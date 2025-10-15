import SwiftUI

struct HomeView: View {
    @EnvironmentObject var spotifyViewModel: SpotifyViewModel
    @EnvironmentObject var searchViewModel: GenericSearchViewModel<SongDetail, SearchSongResult>
    @EnvironmentObject var appState: AppState

    @State private var isSearching = false

    var body: some View {
        VStack(spacing: 0) {
            if appState.isSpotifyConnected == .istrue {
                // Normal content when Spotify is connected
                if isSearching {
                    SearchbarView<SongDetail, SearchSongResult>(
                        isSearching: $isSearching,
                        placeholderText: "Search songs"
                    )
                    .padding(.top, 10)
                    .transition(.move(edge: .top))
                    .zIndex(2)
                }

                ZStack {
                    if isSearching && !searchViewModel.searchResults.isEmpty {
                        searchResultsList
                    } else {
                        songHistoryList
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
                                        to: nil, from: nil, for: nil
                                    )
                                }
                            }
                            .zIndex(1)
                    }
                }
            } else if appState.isSpotifyConnected == .loading {
                // Loading state
                VStack {
                    ProgressView()
                    Text("Loading...")
                        .font(.subheadline)
                        .foregroundColor(Color.themeSecondary)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Empty state
                spotifyNotConnectedView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.themeBackground.ignoresSafeArea())
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if appState.isSpotifyConnected == .istrue {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color.themePrimary)
                        .onTapGesture {
                            withAnimation { isSearching.toggle() }
                        }
                }
            }
        }
        .applyDefaultTabBarStyling()
    }

    private var spotifyNotConnectedView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(Color.themeSecondary.opacity(0.5))

            VStack(spacing: 12) {
                Text("Connect to Spotify")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.themePrimary)

                Text("Connect your Spotify account to see your listening history and real-time updates")
                    .font(.subheadline)
                    .foregroundColor(Color.themeSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button(action: {
                Task {
                    await appState.connectSpotify()
                }
            }) {
                HStack {
                    Image(systemName: "link")
                    Text("Connect Spotify")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.spotifyGreen)
                .cornerRadius(25)
            }
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var searchResultsList: some View {
        List {
            ForEach(searchViewModel.searchResults) { result in
                NavigationLink(destination: destinationView(for: result)) {
                    ClickableSongRowView(song: result, isInHistory: false, isPlaying: false)
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

    private var songHistoryList: some View {
        List {
            if let currentlyPlayingSong = spotifyViewModel.currentlyPlaying {
                NavigationLink(destination: destinationView(for: currentlyPlayingSong)) {
                    ClickableSongRowView(song: currentlyPlayingSong, isInHistory: true, isPlaying: true)
                        .id(spotifyViewModel.currentlyPlaying?.track_id)
                }
                .listRowBackground(Color.themeElement)
            }

            ForEach(spotifyViewModel.sortedSongs) { song in
                NavigationLink(destination: destinationView(for: song)) {
                    ClickableSongRowView(song: song, isInHistory: true, isPlaying: false)
                }
                .listRowBackground(Color.themeElement)
                .onAppear {
                    if song.id == spotifyViewModel.sortedSongs.last?.id {
                        Task {
                            await spotifyViewModel.fetchOlderPlaysHistory()
                        }
                    }
                }
            }

            if spotifyViewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.themeBackground)
        .refreshable {
            await spotifyViewModel.loadCurrentlyPlaying()
            await spotifyViewModel.refreshHistory()
        }
        .onAppear {
            Task {
                await spotifyViewModel.loadCurrentlyPlaying()
                if spotifyViewModel.songHistory.isEmpty {
                    await spotifyViewModel.refreshHistory()
                }
            }
        }
    }

    private func destinationView(for result: SongDetail) -> some View {
        SongDetailView(song: result)
    }
}
