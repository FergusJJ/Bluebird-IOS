import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ProfileHeadlineView()
                Divider()
                // TODO: - need to fix the horizontal padding
                VStack {
                    VStack {
                        HorizontalScrollSection.tracks(
                            title: "Your Pinned Tracks",
                            items: profileViewModel.pinnedTracks
                        )
                        .padding(.horizontal)
                    }
                    Divider()
                    VStack {
                        HorizontalScrollSection.albums(
                            title: "Your Pinned Albums",
                            items: profileViewModel.pinnedAlbums
                        )
                        .padding(.horizontal)
                    }
                    Divider()
                    VStack {
                        HorizontalScrollSection.artists(
                            title: "Your Pinned Artists",
                            items: profileViewModel.pinnedArtists
                        )
                        .padding(.horizontal)
                    }
                    Divider()
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
                        .foregroundColor(Color.babyBlue)
                }
            }
        }
    }

    /* @ViewBuilder
     func pinnedAlbumsSection() -> some View {
         if let pinnedAlbums = profileViewModel.pinnedAlbums,
             !pinnedAlbums.isEmpty
         {
             VStack {
                 HorizontalScrollSection.albums(
                     title: "Your Pinned Albums",
                     items: pinnedAlbums
                 )
             }
         }
     }
     */
}
