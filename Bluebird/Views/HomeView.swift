import SwiftUI

struct HomeView: View {
    @EnvironmentObject var spotifyViewModel: SpotifyViewModel
    @EnvironmentObject var searchViewModel: SearchViewModel

    @State private var isSearching = false

    var body: some View {
        VStack(spacing: 0) {
            if isSearching {
                SearchbarView(isSearching: $isSearching)
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.darkBackground.ignoresSafeArea())
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.nearWhite)
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
                    ClickableSongRowView(song: result, isInHistory: false, isPlaying: false)
                }
                .listRowBackground(Color.darkElement)
            }
            if searchViewModel.isSearchingSong {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.darkBackground)
    }

    private var songHistoryList: some View {
        List {
            if let currentlyPlayingSong = spotifyViewModel.currentlyPlaying {
                NavigationLink(destination: destinationView(for: currentlyPlayingSong)) {
                    ClickableSongRowView(song: currentlyPlayingSong, isInHistory: true, isPlaying: true)
                        .id(spotifyViewModel.currentlyPlaying?.track_id)
                }
                .listRowBackground(Color.darkElement)
            }

            ForEach(spotifyViewModel.sortedSongs) { song in
                NavigationLink(destination: destinationView(for: song)) {
                    ClickableSongRowView(song: song, isInHistory: true, isPlaying: false)
                }
                .listRowBackground(Color.darkElement)
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
        .background(Color.darkBackground)
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
