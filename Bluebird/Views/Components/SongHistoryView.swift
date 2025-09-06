import Foundation
import SwiftUI

struct SongHistoryView: View {
    @EnvironmentObject var spotifyViewModel: SpotifyViewModel

    var body: some View {
        List {
            if let currentlyPlayingSong = spotifyViewModel.currentlyPlaying {
                SongRowView(
                    song: currentlyPlayingSong,
                    isPlaying: true
                )
                .listRowBackground(Color.darkElement)
            }
            ForEach(spotifyViewModel.sortedSongs) { song in
                SongRowView(
                    song: song,
                    isPlaying: false
                )
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
}
