import SwiftUI

struct StatsView: View {
    @EnvironmentObject var statsViewModel: StatsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("This is the stats view")
                Text("\(statsViewModel.getCurrentlyPlayingSong())")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.darkBackground.ignoresSafeArea(edges: .all))
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.inline)
        .applyDefaultTabBarStyling()
    }
}
