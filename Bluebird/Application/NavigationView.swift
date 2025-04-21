import SwiftUI

struct NavigationView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.isLoggedIn == .loading || appState.isSpotifyConnected == .loading {
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
                        VStack(spacing: 20) {
                            Text("Welcome Home!")
                                .font(.title)
                            Spacer()
                            Button("Simulate Logout") {
                                appState.isLoggedIn = .isfalse
                                appState.isSpotifyConnected = .isfalse
                                print(
                                    "Simulated Logout -> isLoggedIn = .isfalse, isSpotifyConnected = .isfalse"
                                )
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                        .padding()

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
        .task {
            appState.initAppState()
        }
    }
}
