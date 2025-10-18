import SwiftUI

struct TrendingListView: View {
    @EnvironmentObject var socialViewModel: SocialViewModel

    @Binding var selectedSong: SongDetail?

    var body: some View {
        ScrollView {
            Group {
                if socialViewModel.isLoadingTrending {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if socialViewModel.trendingTracks.isEmpty {
                    emptyState
                } else {
                    trendingList
                }
            }
            .navigationDestination(item: $selectedSong) { song in
                SongDetailView(
                    trackID: song.track_id,
                    imageURL: song.album_image_url,
                    name: song.name
                )
            }
        }
        .refreshable {
            await socialViewModel.fetchTrendingTracks()
        }
    }

    private var trendingList: some View {
        LazyVStack(spacing: 8, pinnedViews: []) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2)
                        .foregroundColor(Color.themeAccent)
                    Text("Trending This Week")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.themePrimary)
                }
                Text("Most played tracks across all users")
                    .font(.subheadline)
                    .foregroundColor(Color.themeSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 8)

            // Trending tracks
            ForEach(Array(displayedTracks.enumerated()), id: \.element.id) { index, trendingTrack in
                Button(action: {
                    selectedSong = trendingTrack.track
                }) {
                    TrendingTrackRowView(
                        rank: index + 1,
                        track: trendingTrack.track
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.themeElement)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 16)
            }

            // See All / Show Less button
            if socialViewModel.trendingTracks.count > 5 {
                Button(action: {
                    withAnimation {
                        socialViewModel.toggleShowAllTrending()
                    }
                }) {
                    HStack {
                        Spacer()
                        Text(socialViewModel.showAllTrending ? "Show Less" : "See All Trending (\(socialViewModel.trendingTracks.count))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.themeAccent)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                }
                .padding(.horizontal, 16)
            }
        }
        .background(Color.themeBackground)
    }

    private var displayedTracks: [TrendingTrack] {
        if socialViewModel.showAllTrending {
            return socialViewModel.trendingTracks
        } else {
            return Array(socialViewModel.trendingTracks.prefix(5))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(Color.themePrimary.opacity(0.5))

            VStack(spacing: 12) {
                Text("No Trending Tracks")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.themePrimary)

                Text("Check back later to see what's popular")
                    .font(.body)
                    .foregroundColor(Color.themePrimary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.themeBackground)
    }
}
