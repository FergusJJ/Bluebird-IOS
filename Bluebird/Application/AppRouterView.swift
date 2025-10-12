import SwiftUI

struct AppRouterView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var spotifyView: SpotifyViewModel
    @Environment(\.colorScheme) var colorScheme

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
                NavigationStack {
                    SocialView()
                }
                .toolbarBackground(Color.themeBackground, for: .tabBar)
                .toolbarColorScheme(colorScheme, for: .tabBar)
                .tabItem {
                    Label("Social", systemImage: "music.note.house.fill")
                }
                NavigationStack {
                    HomeView()
                }
                .toolbarBackground(Color.themeBackground, for: .tabBar)
                .toolbarColorScheme(colorScheme, for: .tabBar)
                .tabItem {
                    Label("History", systemImage: "music.note.list")
                }
                NavigationStack {
                    StatsView()
                }
                .toolbarBackground(Color.themeBackground, for: .tabBar)
                .toolbarColorScheme(colorScheme, for: .tabBar)
                .tabItem {
                    Label("Stats", systemImage: "chart.pie")
                }
                NavigationStack {
                    ProfileViewV2()
                }
                .toolbarBackground(Color.themeBackground, for: .tabBar)
                .toolbarColorScheme(colorScheme, for: .tabBar)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
            }
            .toolbarBackground(Color.themeBackground, for: .tabBar)
            .toolbarColorScheme(colorScheme, for: .tabBar)
            .applyAdaptiveNavigationBar()
        }
    }
}
