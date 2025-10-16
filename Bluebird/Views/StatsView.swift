import SwiftUI

struct StatsView: View {
    @EnvironmentObject var statsViewModel: StatsViewModel
    @EnvironmentObject var appState: AppState

    @State private var selectedTrack: TrackWithPlayCount?
    @State private var selectedArtist: ArtistWithPlayCount?
    @State private var statsNumDays: Int = 14

    var body: some View {
        if appState.isSpotifyConnected == .istrue {
            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        percentageChange()
                        Spacer()
                        DaysToggleButton(forDays: $statsNumDays)
                    }
                    .padding(.top, 0)
                    Text("Weekly Plays")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.themePrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    DailyPlaysBarGraph(dailyPlays: statsViewModel.dailyPlays)
                        .frame(height: 250)

                    Text("Listening Clock")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.themePrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    HourlyPlaysClockView(
                        hourlyPlays: statsViewModel.hourlyPlays
                    )
                    .aspectRatio(1, contentMode: .fit)

                    // MARK: - weekly comparison

                    VStack(spacing: 16) {
                        HStack(spacing: 8) {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(Color.themeAccent)
                                .font(.system(size: 16))
                            Text("Weekly Listening")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(Color.themePrimary)
                            Spacer()
                            Text("Past 7 Days")
                                .font(.caption)
                                .foregroundColor(
                                    Color.themePrimary.opacity(0.5)
                                )
                        }
                        WeeklyStatsComparisonCard(
                            comparison: statsViewModel.weeklyComparison
                        )
                    }

                    // MARK: - top tracks/artists

                    Divider()
                    if !statsViewModel.topArtists.artists.isEmpty {
                        topArtists()
                    }
                    if !statsViewModel.topTracks.tracks.isEmpty {
                        topTracks()
                    }

                    Divider()
                        .padding(.vertical, 8)
                    VStack(spacing: 16) {
                        HStack(spacing: 8) {
                            Image(systemName: "chart.pie.fill")
                                .foregroundColor(Color.themeAccent)
                                .font(.system(size: 16))
                            Text("Top Genres")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(Color.themePrimary)
                            Spacer()
                            Text("Past 2 Weeks")
                                .font(.caption)
                                .foregroundColor(
                                    Color.themePrimary.opacity(0.5)
                                )
                        }
                        TopGenresBarGraph(allGenres: statsViewModel.topGenres)
                            .frame(height: 250)
                    }

                    // MARK: - discoveries

                    if !statsViewModel.discoveredArtists.isEmpty
                        || !statsViewModel.discoveredTracks.isEmpty
                    {
                        Divider()
                            .padding(.vertical, 8)
                        VStack(spacing: 16) {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(Color.themeAccent)
                                    .font(.system(size: 16))
                                Text("New Discoveries")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.themePrimary)
                                Spacer()
                                Text("Past 7 Days")
                                    .font(.caption)
                                    .foregroundColor(
                                        Color.themePrimary.opacity(0.5)
                                    )
                            }
                            if !statsViewModel.discoveredArtists.isEmpty {
                                discoveredArtists()
                            }
                            if !statsViewModel.discoveredTracks.isEmpty {
                                discoveredTracks()
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
            .background(Color.themeBackground.ignoresSafeArea(edges: .all))
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
            .applyDefaultTabBarStyling()
            .task {
                await withTaskGroup(of: Void.self) { group in
                    group.addTask {
                        await statsViewModel.fetchHourlyPlays(for: statsNumDays)
                    }
                    group.addTask {
                        await statsViewModel.fetchDailyPlays()
                    }
                    group.addTask {
                        await statsViewModel.fetchTopTracks(for: statsNumDays)
                    }
                    group.addTask {
                        await statsViewModel.fetchTopArtists(for: statsNumDays)
                    }
                    group.addTask {
                        await statsViewModel.fetchTopGenres(for: statsNumDays)
                    }
                    group.addTask {
                        await statsViewModel.fetchDiscoveredTracksArtists()
                    }
                    group.addTask {
                        await statsViewModel.fetchWeeklyStatsComparison()
                    }
                }
            }
            .onChange(of: statsNumDays) { _, _ in
                Task { @MainActor in
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask {
                            await statsViewModel.fetchHourlyPlays(
                                for: statsNumDays
                            )
                        }
                        group.addTask {
                            await statsViewModel.fetchDailyPlays()
                        }
                        group.addTask {
                            await statsViewModel.fetchTopTracks(
                                for: statsNumDays
                            )
                        }
                        group.addTask {
                            await statsViewModel.fetchTopArtists(
                                for: statsNumDays
                            )
                        }
                        group.addTask {
                            await statsViewModel.fetchTopGenres(
                                for: statsNumDays
                            )
                        }
                    }
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
        } else if appState.isSpotifyConnected == .loading {
            VStack {
                ProgressView()
                Text("Loading...")
                    .font(.subheadline)
                    .foregroundColor(Color.themeSecondary)
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.themeBackground.ignoresSafeArea())
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
            .applyDefaultTabBarStyling()
        } else {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "chart.pie")
                    .font(.system(size: 60))
                    .foregroundColor(Color.themeSecondary.opacity(0.5))

                VStack(spacing: 12) {
                    Text("Connect to Spotify")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.themePrimary)

                    Text(
                        "Connect your Spotify account to see detailed stats and insights about your music"
                    )
                    .font(.subheadline)
                    .foregroundColor(Color.themeSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                }

                Button(action: {
                    Task {
                        await appState.connectSpotify()
                    }
                }) {
                    HStack {
                        Image(systemName: "link")
                        Text("Connect Spotify")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.spotifyGreen)
                    .cornerRadius(25)
                }
                .padding(.top, 8)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.themeBackground.ignoresSafeArea())
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
            .applyDefaultTabBarStyling()
        }
    }

    @ViewBuilder
    fileprivate func topArtists() -> some View {
        VStack(spacing: 12) {
            if let topArtist = statsViewModel.topArtists
                .artists[0]
            {
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
                if let artist2 = statsViewModel.topArtists
                    .artists[
                        1
                    ]
                {
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
                if let artist3 = statsViewModel.topArtists
                    .artists[
                        2
                    ]
                {
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

    @ViewBuilder
    fileprivate func topTracks() -> some View {
        Spacer()
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
                if let track2 = statsViewModel.topTracks.tracks[
                    1
                ] {
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
                if let track3 = statsViewModel.topTracks.tracks[
                    2
                ] {
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

    @ViewBuilder
    fileprivate func discoveredTracks() -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Tracks")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(
                        Color.themePrimary.opacity(0.7)
                    )
                Spacer()
                Text(
                    "\(statsViewModel.discoveredTracks.count) new"
                )
                .font(.caption)
                .foregroundColor(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.15))
                )
            }

            if let firstTrack = statsViewModel
                .discoveredTracks.first
            {
                TopEntityCard(
                    imageURL: firstTrack.track
                        .album_image_url,
                    name: firstTrack.track.name,
                    playCount: firstTrack.play_count,
                    isTop: true,
                    badgeText: "Most Played"
                )
                .onTapGesture {
                    selectedTrack = firstTrack
                }
            }

            HStack(spacing: 12) {
                if statsViewModel.discoveredTracks.count
                    > 1
                {
                    TopEntityCard(
                        imageURL:
                        statsViewModel
                            .discoveredTracks[
                                1
                            ].track.album_image_url,
                        name:
                        statsViewModel
                            .discoveredTracks[
                                1
                            ].track.name,
                        playCount:
                        statsViewModel
                            .discoveredTracks[
                                1
                            ].play_count,
                        isTop: false,
                        badgeText: ""
                    )
                    .onTapGesture {
                        selectedTrack =
                            statsViewModel
                                .discoveredTracks[
                                    1
                                ]
                    }
                }

                if statsViewModel.discoveredTracks.count
                    > 2
                {
                    TopEntityCard(
                        imageURL:
                        statsViewModel
                            .discoveredTracks[
                                2
                            ].track.album_image_url,
                        name:
                        statsViewModel
                            .discoveredTracks[
                                2
                            ].track.name,
                        playCount:
                        statsViewModel
                            .discoveredTracks[
                                2
                            ].play_count,
                        isTop: false,
                        badgeText: ""
                    )
                    .onTapGesture {
                        selectedTrack =
                            statsViewModel
                                .discoveredTracks[
                                    2
                                ]
                    }
                } else if statsViewModel
                    .discoveredTracks
                    .count > 1
                {
                    Color.clear
                }
            }
        }
    }

    @ViewBuilder
    fileprivate func discoveredArtists() -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Artists")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(
                        Color.themePrimary.opacity(0.7)
                    )
                Spacer()
                Text(
                    "\(statsViewModel.discoveredArtists.count) new"
                )
                .font(.caption)
                .foregroundColor(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.15))
                )
            }

            if let firstArtist = statsViewModel
                .discoveredArtists.first
            {
                TopEntityCard(
                    imageURL: firstArtist.artist
                        .spotify_uri,
                    name: firstArtist.artist.name,
                    playCount: firstArtist.play_count,
                    isTop: true,
                    badgeText: "Most Played"
                )
                .onTapGesture {
                    selectedArtist = firstArtist
                }
            }

            HStack(spacing: 12) {
                if statsViewModel.discoveredArtists
                    .count
                    > 1
                {
                    TopEntityCard(
                        imageURL:
                        statsViewModel
                            .discoveredArtists[
                                1
                            ].artist.spotify_uri,
                        name:
                        statsViewModel
                            .discoveredArtists[
                                1
                            ].artist.name,
                        playCount:
                        statsViewModel
                            .discoveredArtists[
                                1
                            ].play_count,
                        isTop: false,
                        badgeText: ""
                    )
                    .onTapGesture {
                        selectedArtist =
                            statsViewModel
                                .discoveredArtists[
                                    1
                                ]
                    }
                }

                if statsViewModel.discoveredArtists
                    .count
                    > 2
                {
                    TopEntityCard(
                        imageURL:
                        statsViewModel
                            .discoveredArtists[
                                2
                            ].artist.spotify_uri,
                        name:
                        statsViewModel
                            .discoveredArtists[
                                2
                            ].artist.name,
                        playCount:
                        statsViewModel
                            .discoveredArtists[
                                2
                            ].play_count,
                        isTop: false,
                        badgeText: ""
                    )
                    .onTapGesture {
                        selectedArtist =
                            statsViewModel
                                .discoveredArtists[
                                    2
                                ]
                    }
                } else if statsViewModel
                    .discoveredArtists
                    .count > 1
                {
                    Color.clear
                }
            }
        }
    }

    @ViewBuilder
    private func percentageChange() -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(statsViewModel.thisWeekTotalPlays) plays this week")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color.themePrimary)

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
