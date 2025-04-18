import SwiftUI

@main
struct BluebirdApp: App {
    @StateObject private var appState = AppState()
    var body: some Scene {
        WindowGroup {
            NavigationView()
                .environmentObject(appState)
        }
    }
}
