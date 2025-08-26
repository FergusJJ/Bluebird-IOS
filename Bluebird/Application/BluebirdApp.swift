import SwiftUI

@MainActor func createViewModel(appState: AppState) -> SpotifyViewModel? {
    do {
        let manager = try BluebirdAPIManager()
        return SpotifyViewModel(appState: appState, spotifyAPIService: manager)
    } catch {
        print("FATAL ERROR: Failed to initialize BluebirdAPIManager: \(error)")
        return nil
    }
}

@main
struct BluebirdApp: App {
    @StateObject private var appState: AppState
    @State private var spotifyViewModel: SpotifyViewModel?

    init() {
        let state = AppState()
        _appState = StateObject(wrappedValue: state)
        _spotifyViewModel = State(initialValue: createViewModel(appState: state))
    }

    var body: some Scene {
        WindowGroup {
            // If appState isnt initialized here ErrorAlertViewModifier fails
            ContentView(appState: appState, spotifyViewModel: spotifyViewModel)
                .environmentObject(appState)
        }
    }
}
