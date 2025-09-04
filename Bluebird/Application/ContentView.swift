import SwiftUI

struct ContentView: View {
    @ObservedObject var appState: AppState

    @StateObject private var spotifyViewModel: SpotifyViewModel
    @StateObject private var profileViewModel: ProfileViewModel

    @Environment(\.scenePhase) var scenePhase

    init(appState: AppState, apiManager: BluebirdAPIManager) {
        self.appState = appState
        _spotifyViewModel = StateObject(wrappedValue: SpotifyViewModel(appState: appState, spotifyAPIService: apiManager))
        _profileViewModel = StateObject(wrappedValue: ProfileViewModel(appState: appState, bluebirdAccountAPIService: apiManager))
    }

    var body: some View {
        Group {
            AppRouterView()
                .environmentObject(spotifyViewModel)
                .environmentObject(profileViewModel)
                .modifier(ErrorAlertViewModifier())
                .onOpenURL { url in
                    handleUrl(url)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    handleScenePhase(newPhase)
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
