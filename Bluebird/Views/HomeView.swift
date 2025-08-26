import SwiftUI

struct HomeView: View {
    @EnvironmentObject var spotifyViewModel: SpotifyViewModel

    var body: some View {
        VStack {
            SongHistoryView()
        }
    }
}
