import SwiftUI

@MainActor func createViewModel() -> SpotifyViewModel? {
    do {
        let manager = try BluebirdAPIManager()
        return SpotifyViewModel(spotifyAPIService: manager)
    } catch {
        print("FATAL ERROR: Failed to initialize BluebirdAPIManager: \(error)")
        return nil
    }
}

@main
struct BluebirdApp: App {
    @StateObject private var appState = AppState()
    @State private var spotifyView: SpotifyViewModel? = createViewModel()

    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            if let spotifyVM = spotifyView {
                NavigationView()
                    .environmentObject(appState)
                    .environmentObject(spotifyVM)
                    .alert(item: $appState.errorToDisplay) { displayableError in
                        Alert(
                            title: Text("Error"), // might want to make this more specific
                            message: Text(
                                displayableError.localizedDescription
                            ),
                            dismissButton: .default(Text("OK")) {
                                print(
                                    "Error alert dismissed. Error was: \(displayableError.localizedDescription)"
                                )
                            }
                        )
                    }
                    .onOpenURL { url in
                        // if more urls added then I think would need branching here
                        // also get expiry but spotify tokens only last an hour and are
                        // refreshed every app load anywya
                        guard url.scheme == "com.fergusjj.bluebird" else {
                            return
                        }
                        guard
                            let components = URLComponents(
                                url: url,
                                resolvingAgainstBaseURL: true
                            ),
                            let queryItems = components.queryItems
                        else { return }
                        if let accessToken = queryItems.first(where: {
                            $0.name == "access_token"
                        })?
                            .value,
                            let refreshToken = queryItems.first(where: {
                                $0.name == "refresh_token"
                            })?
                            .value,
                            let tokenExpiryString = queryItems.first(where: {
                                $0.name == "expires_in"
                            })?
                            .value
                        {
                            // HERE can just use handleInitialSpotifyConnection?
                            let err = appState.saveSpotifyCredentials(
                                access: accessToken,
                                refresh: refreshToken,
                                tokenExpiry: tokenExpiryString
                            )
                            if err != nil {
                                let localizedDescription =
                                    err?.localizedDescription
                                        ?? "no localizedDescription"
                                print("\(localizedDescription)")
                                return
                            }
                            Task {
                                print(
                                    "USER CONNECTED SPOTIFY FOR FIRST TIME, SAVING CLIENT id"
                                )
                                await appState.handleInitialSpotifyConnection(
                                    accessToken: accessToken,
                                    refreshToken: refreshToken,
                                    tokenExpiry: tokenExpiryString
                                )
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
            } else {
                VStack(spacing: 15) {
                    Image(systemName: "exclamationmark.octagon.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.red)
                    Text("Application Initialization Failed")
                        .font(.title2).bold()
                    Text(
                        "A critical service (API Manager) could not be started. Please check your configuration or contact support."
                    )
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                }
                .padding()
            }
        }
    }
}
