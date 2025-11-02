import SwiftUI

struct AppRouterView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var spotifyView: SpotifyViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            if appState.isLoggedIn == .loading {
                VStack {
                    Text("Loading...")
                    ProgressView()
                }
            } else if appState.isLoggedIn == .isfalse {
                AuthFlowView()
            } else if appState.isInitialSignup && appState.isSpotifyConnected == .isfalse {
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
                        HistoryView()
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
                .overlay(
                    Group {
                        if appState.shouldShowOnboarding {
                            OnboardingOverlayView()
                                .transition(.opacity)
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: appState.shouldShowOnboarding)
                )
                .overlay(
                    Group {
                        if appState.shouldShowSpotifyModal {
                            Color.black.opacity(0.3)
                                .ignoresSafeArea()
                                .onTapGesture {
                                    appState.dismissSpotifyModal()
                                }

                            VStack {
                                Spacer()
                                SpotifyConnectionModal()
                                    .transition(.move(edge: .bottom))
                            }
                            .ignoresSafeArea(edges: .bottom)
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: appState.shouldShowSpotifyModal)
                )
            }
        }
    }
}
