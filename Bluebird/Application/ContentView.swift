import SwiftUI

struct ContentView: View {
    @ObservedObject var appState: AppState

    @StateObject private var spotifyViewModel: SpotifyViewModel
    @StateObject private var profileViewModel: ProfileViewModel
    @StateObject private var searchViewModel: SearchViewModel
    @StateObject private var statsViewModel: StatsViewModel

    @Environment(\.scenePhase) var scenePhase

    init(appState: AppState, apiManager: BluebirdAPIManager) {
        self.appState = appState
        _spotifyViewModel = StateObject(wrappedValue: SpotifyViewModel(appState: appState, spotifyAPIService: apiManager))
        _profileViewModel = StateObject(wrappedValue: ProfileViewModel(appState: appState, bluebirdAccountAPIService: apiManager))
        _searchViewModel = StateObject(wrappedValue: SearchViewModel(appState: appState, bluebirdAccountAPIService: apiManager))
        _statsViewModel = StateObject(wrappedValue: StatsViewModel(appState: appState, bluebirdAccountAPIService: apiManager))
    }

    var body: some View {
        Group {
            AppRouterView()
                .environmentObject(spotifyViewModel)
                .environmentObject(profileViewModel)
                .environmentObject(searchViewModel)
                .environmentObject(statsViewModel)
                //
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
           let tokenExpiryString = queryItems.first(where: { $0.name == "expires_in" })?.value,
           let scopes = queryItems.first(where: { $0.name == "scopes" })?.value
        {
            Task {
                await appState.handleInitialSpotifyConnection(
                    accessToken: accessToken,
                    refreshToken: refreshToken,
                    tokenExpiry: tokenExpiryString,
                    scopes: scopes
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
