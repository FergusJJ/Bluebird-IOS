import SwiftUI

struct AppRouterView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var spotifyView: SpotifyViewModel

    var body: some View {
        if appState.isLoggedIn == .loading || appState.isSpotifyConnected == .loading {
            VStack {
                Text("Loading...")
                ProgressView()
            }
        } else if appState.isLoggedIn == .isfalse {
            AuthFlowView()
        } else if appState.isSpotifyConnected == .isfalse {
            SpotifyView()
        } else {
            TabView {
                HomeView()
                    .toolbarBackground(Color.darkBackground, for: .tabBar)
                    .toolbarColorScheme(.dark, for: .tabBar)
                    .tabItem {
                        Label("Home", systemImage: "music.note.list")
                    }
                ProfileView()
                    .toolbarBackground(Color.darkBackground, for: .tabBar)
                    .toolbarColorScheme(.dark, for: .tabBar)
                    .tabItem {
                        Label("Profile", systemImage: "person.crop.circle")
                    }
            }
        }
    }
}
