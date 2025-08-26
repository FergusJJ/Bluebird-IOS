import SwiftUI

struct AppRouterView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var spotifyView: SpotifyViewModel

    var body: some View {
        Group {
            if appState.isLoggedIn == .loading
                || appState.isSpotifyConnected == .loading
            {
                VStack {
                    Text("Loading...")
                    ProgressView()
                }
            } else {
                switch appState.isLoggedIn {
                case .isfalse:
                    AuthFlowView()

                case .istrue:
                    switch appState.isSpotifyConnected {
                    case .isfalse:
                        SpotifyView()

                    case .istrue: // Logged in AND Spotify IS connected
                        TabView {
                            HomeView()
                                .tabItem {
                                    Label("Home", systemImage: "music.note.list")
                                }
                        }

                    case .loading:
                        VStack {
                            Text("Checking Spotify Status...")
                            ProgressView()
                        }
                    }

                case .loading:
                    VStack {
                        Text("Unexpected Loading State...")
                        ProgressView()
                    }
                }
            }
        }
    }
}
