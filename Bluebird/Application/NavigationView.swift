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

                        VStack(spacing: 20) {
                            Text("Connect Spotify")
                                .font(.title)
                            Text("Please connect your Spotify account.")
                            Button("Simulate Connect") {
                                appState.isSpotifyConnected = .istrue
                                print("Simulated Spotify Connect -> isSpotifyConnected = .istrue")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        }
                        .padding()

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
            await appState.initAppState()
        }
    }
}
