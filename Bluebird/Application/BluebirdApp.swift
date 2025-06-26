import SwiftUI

// The global factory function remains the same for now
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
    // @StateObject private var appState = AppState()
    // @State private var spotifyViewModel: SpotifyViewModel? = createViewModel()

    // old
    @StateObject private var appState = AppState()
    @State private var spotifyViewModel: SpotifyViewModel? = createViewModel()

    var body: some Scene {
        WindowGroup {
            // If appState isnt initialized here ErrorAlertViewModifier fails
            ContentView(appState: appState, spotifyViewModel: spotifyViewModel)
                .environmentObject(appState)
        }
    }
}
