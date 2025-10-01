import SwiftUI

struct StatsView: View {
    @EnvironmentObject var statsViewModel: StatsViewModel

    @State private var selectedTrack: TrackWithPlayCount?
    @State private var selectedArtist: ArtistWithPlayCount?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                percentageChange()
                Text("Weekly Plays")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.nearWhite)
                    .frame(maxWidth: .infinity, alignment: .leading)
                DailyPlaysBarGraph(dailyPlays: statsViewModel.dailyPlays)
                    .frame(height: 250)
                Divider()
                Text("Listening Clock")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.nearWhite)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HourlyPlaysClockView(hourlyPlays: statsViewModel.hourlyPlays)
                    .aspectRatio(1, contentMode: .fit)
                Divider()
                if !statsViewModel.topArtists.artists.isEmpty {
                    /* Text("Top Artists")
                         .font(.headline)
                         .fontWeight(.bold)
                         .foregroundColor(Color.nearWhite)
                         .frame(maxWidth: .infinity, alignment: .leading)

                     Divider() */
                    VStack(spacing: 12) {
                        if let topArtist = statsViewModel.topArtists.artists[0] {
                            TopEntityCard(
                                imageURL: topArtist.artist.spotify_uri,
                                name: topArtist.artist.name,
                                playCount: topArtist.play_count,
                                isTop: true,
                                badgeText: "Top Artist"
                            ).onTapGesture {
                                selectedArtist = topArtist
                            }
                        }
                        HStack(spacing: 12) {
                            if let artist2 = statsViewModel.topArtists.artists[
                                1
                            ] {
                                TopEntityCard(
                                    imageURL: artist2.artist.spotify_uri,
                                    name: artist2.artist.name,
                                    playCount: artist2.play_count,
                                    isTop: false,
                                    badgeText: ""
                                ).onTapGesture {
                                    selectedArtist = artist2
                                }
                            }
                            if let artist3 = statsViewModel.topArtists.artists[
                                2
                            ] {
                                TopEntityCard(
                                    imageURL: artist3.artist.spotify_uri,
                                    name: artist3.artist.name,
                                    playCount: artist3.play_count,
                                    isTop: false,
                                    badgeText: ""
                                ).onTapGesture {
                                    selectedArtist = artist3
                                }
                            } else {
                                Color.clear
                            }
                        }
                    }
                }

                if !statsViewModel.topTracks.tracks.isEmpty {
                    Spacer()
                    /* Text("Top Tracks")
                         .font(.headline)
                         .fontWeight(.bold)
                         .foregroundColor(Color.nearWhite)
                         .frame(maxWidth: .infinity, alignment: .leading)
                     Divider() */
                    VStack(spacing: 12) {
                        if let topTrack = statsViewModel.topTracks.tracks[0] {
                            TopEntityCard(
                                imageURL: topTrack.track.album_image_url,
                                name: topTrack.track.name,
                                playCount: topTrack.play_count,
                                isTop: true,
                                badgeText: "Top Track"
                            ).onTapGesture {
                                selectedTrack = topTrack
                            }
                        }
                        HStack(spacing: 12) {
                            if let track2 = statsViewModel.topTracks.tracks[1] {
                                TopEntityCard(
                                    imageURL: track2.track.album_image_url,
                                    name: track2.track.name,
                                    playCount: track2.play_count,
                                    isTop: false,
                                    badgeText: ""
                                ).onTapGesture {
                                    selectedTrack = track2
                                }
                            }
                            if let track3 = statsViewModel.topTracks.tracks[2] {
                                TopEntityCard(
                                    imageURL: track3.track.album_image_url,
                                    name: track3.track.name,
                                    playCount: track3.play_count,
                                    isTop: false,
                                    badgeText: ""
                                ).onTapGesture {
                                    selectedTrack = track3
                                }
                            } else {
                                Color.clear
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .scrollContentBackground(.hidden)
        .background(Color.darkBackground.ignoresSafeArea(edges: .all))
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.inline)
        .applyDefaultTabBarStyling()
        .task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await statsViewModel.fetchHourlyPlays() }
                group.addTask { await statsViewModel.fetchDailyPlays() }
                group.addTask { await statsViewModel.fetchTopTracks() }
                group.addTask { await statsViewModel.fetchTopArtists() }
            }
        }
        .navigationDestination(item: $selectedArtist) { artist in
            ArtistDetailView(
                artist: SongDetailArtist(
                    id: artist.artist.artist_id,
                    image_url: artist.artist.spotify_uri,
                    name: artist.artist.name
                )
            )
        }
        .navigationDestination(item: $selectedTrack) { track in
            SongDetailView(
                trackID: track.track.track_id,
                imageURL: track.track.album_image_url,
                name: track.track.name
            )
        }
    }

    @ViewBuilder
    private func percentageChange() -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(statsViewModel.thisWeekTotalPlays) plays this week")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color.nearWhite)

            HStack(spacing: 4) {
                Image(
                    systemName: statsViewModel.thisWeekTotalPlays
                        > statsViewModel.lastWeekTotalPlays
                        ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
                )
                .font(.caption)

                Text(
                    String(
                        format: "%.2f%% vs last week",
                        abs(statsViewModel.getPlaysPercentageChange())
                    )
                )
                .font(.caption)
            }
            .foregroundColor(
                statsViewModel.thisWeekTotalPlays
                    > statsViewModel.lastWeekTotalPlays
                    ? Color.green : Color.red
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
