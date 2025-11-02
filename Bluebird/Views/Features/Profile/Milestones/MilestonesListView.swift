import SwiftUI

struct MilestonesListView: View {
    let milestones: [UserMilestone]
    let username: String

    var body: some View {
        List {
            ForEach(milestones, id: \.artist.artist_id) { milestone in
                NavigationLink(destination: ArtistDetailView(
                    artist: SongDetailArtist(
                        id: milestone.artist.artist_id,
                        image_url: milestone.artist.spotify_uri,
                        name: milestone.artist.name
                    )
                )) {
                    ProfileMilestoneRowView(milestone: milestone)
                }
                .listRowBackground(Color.themeElement)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.themeBackground)
        .navigationTitle("\(username)'s Milestones")
        .navigationBarTitleDisplayMode(.inline)
    }
}
