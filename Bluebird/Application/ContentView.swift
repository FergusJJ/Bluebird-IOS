import SwiftUI

struct ContentView: View {
    @ObservedObject var appState: AppState

    @StateObject private var spotifyViewModel: SpotifyViewModel
    @StateObject private var profileViewModel: ProfileViewModel
    @StateObject private var statsViewModel: StatsViewModel
    @StateObject private var socialViewModel: SocialViewModel
    @StateObject private var songSearchViewModel:
        GenericSearchViewModel<
            SongDetail,
            SearchSongResult
        >
    @StateObject private var userSearchViewModel:
        GenericSearchViewModel<UserProfile, SearchUserResult>
    @StateObject private var onboardingManager: OnboardingManager

    @Environment(\.scenePhase) var scenePhase

    init(appState: AppState, apiManager: BluebirdAPIManagerV2) {
        self.appState = appState
        _spotifyViewModel = StateObject(
            wrappedValue: SpotifyViewModel(
                appState: appState,
                spotifyAPIService: apiManager
            )
        )
        _profileViewModel = StateObject(
            wrappedValue: ProfileViewModel(
                appState: appState,
                bluebirdAccountAPIService: apiManager
            )
        )
        _statsViewModel = StateObject(
            wrappedValue: StatsViewModel(
                appState: appState,
                bluebirdAccountAPIService: apiManager
            )
        )
        _socialViewModel = StateObject(
            wrappedValue: SocialViewModel(
                appState: appState,
                bluebirdAccountAPIService: apiManager
            )
        )
        _songSearchViewModel = StateObject(
            wrappedValue: GenericSearchViewModel(
                debounceDuration: .milliseconds(100),
                appState: appState,
                searchFunction: apiManager.searchSongs,
                unwrapFunction: { $0.tracks }
            )
        )
        _userSearchViewModel = StateObject(
            wrappedValue: GenericSearchViewModel(
                debounceDuration: .milliseconds(100),
                appState: appState,
                searchFunction: apiManager.searchUsers,
                unwrapFunction: {
                    $0.users
                }
            )
        )
        _onboardingManager = StateObject(
            wrappedValue: OnboardingManager(
                appState: appState,
                apiService: apiManager
            )
        )
    }

    var body: some View {
        Group {
            AppRouterView()
                .environmentObject(spotifyViewModel)
                .environmentObject(profileViewModel)
                .environmentObject(songSearchViewModel)
                .environmentObject(userSearchViewModel)
                .environmentObject(statsViewModel)
                .environmentObject(socialViewModel)
                .environmentObject(onboardingManager)
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

        guard
            let components = URLComponents(
                url: url,
                resolvingAgainstBaseURL: true
            ),
            let queryItems = components.queryItems
        else { return }

        if let accessToken = queryItems.first(where: {
            $0.name == "access_token"
        })?.value,
            let refreshToken = queryItems.first(where: {
                $0.name == "refresh_token"
            })?.value,
            let tokenExpiryString = queryItems.first(where: {
                $0.name == "expires_in"
            })?.value,
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
