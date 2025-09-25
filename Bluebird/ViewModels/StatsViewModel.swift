import SwiftUI

@MainActor
class StatsViewModel: ObservableObject {
    private var appState: AppState

    private let bluebirdAccountAPIService: BluebirdAccountAPIService
    private let supabaseManager = SupabaseClientManager.shared

    init(
        appState: AppState,
        bluebirdAccountAPIService: BluebirdAccountAPIService
    ) {
        self.appState = appState
        self.bluebirdAccountAPIService = bluebirdAccountAPIService
    }

    func getCurrentlyPlayingSong() -> String {
        return "\(appState.currentSong) - \(appState.currentArtist)"
    }
}
