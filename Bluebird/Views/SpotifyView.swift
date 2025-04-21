import SwiftUI

struct SpotifyView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            Color.spotifyDarkGray
                .ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Connect Spotify")
                    .font(.title)
                    .colorInvert()
                Text("Please connect your Spotify account.")
                    .colorInvert()
                Button("Simulate Connect") {
                    appState.isSpotifyConnected = .istrue
                    print("Simulated Spotify Connect -> isSpotifyConnected = .istrue")
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding()
        }
    }
}
