import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack {
                SongHistoryView()
            }
            .background(Color.darkBackground.ignoresSafeArea(edges: .top))
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // empty for now
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.darkBackground, for: .navigationBar)
            .toolbarBackgroundVisibility(.visible, for: .navigationBar)
        }
    }
}
