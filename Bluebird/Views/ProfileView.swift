import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ProfileHeadlineView()
                    Divider()
                    VStack {
                        HorizontalScrollView(
                            horizontalScrollViewTitle: "Pinned Tracks",
                            scrollViewObjects: profileViewModel.pinnedTracks
                        )
                        Divider()
                        HorizontalScrollView(
                            horizontalScrollViewTitle: "Pinned Albums",
                            scrollViewObjects: profileViewModel.pinnedAlbums
                        )
                        Divider()
                        HorizontalScrollView(
                            horizontalScrollViewTitle: "Pinned Artists",
                            scrollViewObjects: profileViewModel.pinnedArtists
                        )
                    }
                    .padding()
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
            }
            .background(Color.darkBackground.ignoresSafeArea(edges: .top))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(Color.accentColor)
                    }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.darkBackground, for: .navigationBar)
            .toolbarBackgroundVisibility(.visible, for: .navigationBar)
        }
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(Color.darkBackground, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }
}
