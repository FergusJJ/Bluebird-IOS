import SwiftUI

@main
struct BluebirdApp: App {
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            NavigationView()
                .environmentObject(appState)
                .alert(item: $appState.errorToDisplay) { displayableError in
                    Alert(
                        title: Text("Error"), // might want to make this more specific
                        message: Text(displayableError.localizedDescription),
                        dismissButton: .default(Text("OK")) {
                            print("Error alert dismissed. Error was: \(displayableError.localizedDescription)")
                        }
                    )
                }
                .onOpenURL { url in
                    // also get expiry but spotify tokens only last an hour and are
                    // refreshed every app load anywya
                    guard url.scheme == "com.fergusjj.bluebird" else { return }
                    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                          let queryItems = components.queryItems
                    else { return }
                    if let accessToken = queryItems.first(where: { $0.name == "access_token" })?
                        .value,
                        let refreshToken = queryItems.first(where: { $0.name == "refresh_token" })?
                        .value
                    {
                        let err = appState.saveSpotifyCredentials(
                            access: accessToken, refresh: refreshToken
                        )
                        if err != nil {
                            let localizedDescription =
                                err?.localizedDescription ?? "no localizedDescription"
                            print("\(localizedDescription)")
                        }
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
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
    }
}
