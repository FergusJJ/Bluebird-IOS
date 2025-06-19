import SwiftUI

struct HomeView: View {
    @EnvironmentObject var spotifyViewModel: SpotifyViewModel
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 20) {
            Text("This is the new home screen")
                .font(.title)

            if let song = spotifyViewModel.currentlyPlaying {
                SongSlot(
                    currentlyPlaying: true,
                    song: song.song,
                    artists: song.artists,
                    imageURL: URL(string: song.imageUrl)
                )
            } else {
                Text("Nothing playing...")
                Button("Refresh") {
                    Task {
                        let spotifyAccessToken = appState.getSpotifyAccessToken()
                        await spotifyViewModel.loadCurrentlyPlaying(
                            spotifyAccessToken: spotifyAccessToken)
                    }
                }
            }
        }
        .onAppear {
            Task {
                let spotifyAccessToken = appState.getSpotifyAccessToken()
                await spotifyViewModel.loadCurrentlyPlaying(spotifyAccessToken: spotifyAccessToken)
            }
        }
    }
}
