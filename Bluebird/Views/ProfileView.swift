import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel

    var body: some View {
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

        .scrollContentBackground(.hidden)
        .background(Color.darkBackground.ignoresSafeArea(edges: .all))
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .applyDefaultTabBarStyling()
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(Color.accentColor)
                }
            }
        }
    }
}
