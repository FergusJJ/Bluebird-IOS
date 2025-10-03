import SwiftUI

@main
struct BluebirdApp: App {
    @StateObject private var appState: AppState
    private let apiManager: BluebirdAPIManager

    init() {
        apiManager = try! BluebirdAPIManager()
        _appState = StateObject(wrappedValue: AppState())
    }

    var body: some Scene {
        WindowGroup {
            // If appState isnt initialized here ErrorAlertViewModifier fails
            ContentView(appState: appState, apiManager: apiManager)
                .environmentObject(appState)
                .preferredColorScheme(appState.userColorScheme)
        }
    }
}
