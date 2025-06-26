import SwiftUI

struct ContentView: View {
    @ObservedObject var appState: AppState
    var spotifyViewModel: SpotifyViewModel?

    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        Group {
            if let spotifyVM = spotifyViewModel {
                AppRouterView()
                    .environmentObject(spotifyVM)
                    .modifier(ErrorAlertViewModifier())
                    .onOpenURL { url in
                        handleUrl(url)
                    }
                    .onChange(of: scenePhase) { _, newPhase in
                        handleScenePhase(newPhase)
                    }
            } else {
                VStack(spacing: 15) {
                    Image(systemName: "exclamationmark.octagon.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.red)
                    Text("Application Initialization Failed")
                        .font(.title2).bold()
                    Text("A critical service could not be started. Please restart the app or contact support.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            }
        }
    }

    private func handleUrl(_ url: URL) {
        guard url.scheme == "com.fergusjj.bluebird" else { return }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else { return }

        if let accessToken = queryItems.first(where: { $0.name == "access_token" })?.value,
           let refreshToken = queryItems.first(where: { $0.name == "refresh_token" })?.value,
           let tokenExpiryString = queryItems.first(where: { $0.name == "expires_in" })?.value
        {
            let success = appState.saveSpotifyCredentials(
                access: accessToken,
                refresh: refreshToken,
                tokenExpiry: tokenExpiryString
            )

            if !success { return }

            Task {
                await appState.handleInitialSpotifyConnection(
                    accessToken: accessToken,
                    refreshToken: refreshToken,
                    tokenExpiry: tokenExpiryString
                )
            }
        }
    }

    private func handleScenePhase(_ newPhase: ScenePhase) {
        if newPhase == .active {
            Task {
                await appState.handleAppDidBecomeActive()
            }
        } else if newPhase == .inactive {
            print("App scene became inactive")
        } else if newPhase == .background {
            print("App scene entered background")
        }
    }
}
