import SwiftUI

struct SongDetailView: View {
    let trackID: String
    let initialSong: SongDetail?
    let initialImageURL: String
    let initialName: String

    @State private var song: SongDetail?
    @State private var isLoading = false
    @State private var isPinned = false
    @State private var isReposted = false
    @State private var trackTrend: [DailyPlayCount] = []
    @State private var trackLastPlayed: Date?
    @State private var trackUserPercenitile: Double?

    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var spotifyViewModel: SpotifyViewModel
    @EnvironmentObject var statsViewModel: StatsViewModel

    // Convenience initializers
    init(song: SongDetail) {
        trackID = song.track_id
        initialSong = song
        initialImageURL = song.album_image_url
        initialName = song.name
    }

    init(trackID: String, imageURL: String, name: String) {
        self.trackID = trackID
        initialSong = nil
        initialImageURL = imageURL
        initialName = name
    }

    var body: some View {
        ScrollView {
            if let detail = song ?? initialSong {
                detailContent(for: detail)
            } else if isLoading {
                placeholderView(text: "Loading \(initialName)…")
            } else {
                placeholderView(text: "Failed to load song details")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.themeBackground.ignoresSafeArea(edges: .all))
        .navigationTitle(song?.name ?? initialSong?.name ?? initialName)
        .navigationBarTitleDisplayMode(.inline)
        .applyDefaultTabBarStyling()
        .task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await fetchSongIfNeeded() }
                group.addTask { @MainActor in
                    let trackTrendOpt = await statsViewModel.getTrackTrend(
                        for: trackID
                    )
                    if trackTrendOpt != nil {
                        trackTrend = trackTrendOpt!
                    }
                }
                group.addTask { @MainActor in
                    trackLastPlayed = await statsViewModel.getTrackLastPlayed(
                        for: trackID
                    )
                }
                group.addTask { @MainActor in
                    trackUserPercenitile =
                        await statsViewModel.getTrackUserPercentile(
                            for: trackID
                        )
                }
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func detailContent(for song: SongDetail) -> some View {
        HeaderView(for: song)
        TwoStatsView(
            leftLabel: "PLATFORM RANK",
            leftValue: formatUserPercentile(),
            rightLabel: "LAST PLAYED",
            rightValue: formatLastPlayed(),
            valueFontSize: .point(12)
        )
        .padding(12)
        TrackTrendBarGraph(trackTrend: trackTrend)
            .frame(height: 250)
            .padding(12)

        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: song.artists.count > 1 ? "Artists" : "Artist")
            ForEach(song.artists, id: \.id) { artist in
                RowItem(
                    title: artist.name,
                    imageURL: artist.image_url,
                    clipShape: AnyShape(Circle()),
                    systemImage: "chevron.right"
                ) {
                    ArtistDetailView(artist: artist)
                }
            }
        }

        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Album")
            RowItem(
                title: song.album_name,
                imageURL: song.album_image_url,
                clipShape: AnyShape(RoundedRectangle(cornerRadius: 4)),
                systemImage: "chevron.right"
            ) {
                AlbumDetailView(
                    albumID: song.album_id,
                    albumName: song.album_name,
                    albumImageURL: song.album_image_url
                )
            }
        }
    }

    private func onOpenSpotifyTapped(_ uri: String) {
        let spotifyURL = URL(
            string: uri.replacingOccurrences(of: "spotify:", with: "spotify://")
        )!
        if UIApplication.shared.canOpenURL(spotifyURL) {
            UIApplication.shared.open(
                spotifyURL,
                options: [:],
                completionHandler: nil
            )
        }
    }

    @ViewBuilder
    fileprivate func HeaderView(for song: SongDetail) -> some View {
        ZStack {
            CachedAsyncImage(url: URL(string: song.album_image_url)!)
                .aspectRatio(contentMode: .fit)
                .padding(.horizontal, 10)
        }
        .overlay(
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    CircleIconButton(
                        systemName: "arrow.up.right.circle.fill",
                        iconColor: Color.green,
                        backgroundColor: Color.black.opacity(0.6)
                    ) {
                        onOpenSpotifyTapped(song.spotify_url)
                    }

                    Spacer()

                    CircleIconButton(
                        systemName: isReposted
                            ? "arrow.2.squarepath" : "arrow.2.squarepath",
                        iconColor: isReposted
                            ? Color.themeAccent : Color.themePrimary,
                        backgroundColor: Color.themeElement.opacity(0.9)
                    ) {
                        onRepostTapped()
                    }

                    CircleIconButton(
                        systemName: isPinned ? "pin.fill" : "pin",
                        iconColor: isPinned
                            ? Color.themeAccent : Color.themePrimary,
                        backgroundColor: Color.themeElement.opacity(0.9)
                    ) {
                        onPinTapped()
                    }
                }
            }
            .padding(16)
        )
    }

    @ViewBuilder
    private func placeholderView(text: String) -> some View {
        VStack(spacing: 16) {
            CachedAsyncImage(url: URL(string: initialImageURL)!)
                .aspectRatio(contentMode: .fit)
                .padding(.horizontal, 10)
            Text(text)
                .font(.headline)
                .foregroundStyle(.white)
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.themeBackground.ignoresSafeArea(edges: .all))
    }

    private func onPinTapped() {
        if let loadedID = song?.track_id ?? initialSong?.track_id {
            Task {
                let isDelete = isPinned
                isPinned.toggle()
                let success = await profileViewModel.updatePin(
                    for: loadedID,
                    entity: "track",
                    isDelete: isDelete
                )
                if !success {
                    isPinned.toggle()
                }
            }
        } else {
            print("SongDetailView - song and initailSong not loaded")
        }
    }

    // TODO:
    private func onRepostTapped() {
        isReposted.toggle()
        print("Repost toggled: \(isReposted)")
    }

    private func fetchSongIfNeeded() async {
        let pin = Pin(entity_id: trackID, entity_type: .track)
        isPinned = profileViewModel.isPinned(pin)
        guard song == nil, initialSong == nil else { return }
        isLoading = true
        song = await spotifyViewModel.fetchSongDetail(for: trackID)
        isLoading = false
    }

    private func formatLastPlayed() -> String? {
        guard let date = trackLastPlayed else {
            return "no plays"
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short

        return dateFormatter.string(from: date)
    }

    private func formatUserPercentile() -> String? {
        if trackUserPercenitile == nil {
            return nil
        }
        let clampedPercentile = max(0.0, min(100.0, trackUserPercenitile!))
        let percentileInt = Int(clampedPercentile.rounded())
        let rank = 100 - percentileInt
        switch percentileInt {
        case 1 ... 100:
            let topRankPercent = max(1, rank)
            return "Top \(topRankPercent)% of listeners"
        default:
            return "One of the newest listeners"
        }
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(Color.themePrimary.opacity(0.9))
                .padding(.horizontal, 16)
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.themePrimary.opacity(0.2))
                .padding(.horizontal, 16)
        }
        .padding(.top, 16)
    }
}
