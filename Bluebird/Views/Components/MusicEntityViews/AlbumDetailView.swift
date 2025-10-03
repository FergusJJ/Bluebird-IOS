import SwiftUI

struct AlbumDetailView: View {
    let albumID: String
    let initialAlbum: AlbumDetail?
    let initialImageURL: String
    let initialName: String

    @State private var album: AlbumDetail?
    @State private var isLoading = false
    @State private var isPinned = false

    @EnvironmentObject var spotifyViewModel: SpotifyViewModel
    // use to check pins
    @EnvironmentObject var profileViewModel: ProfileViewModel

    // MARK: - Convenience initializers

    init(album: AlbumDetail) {
        albumID = album.album_id
        initialAlbum = album
        initialImageURL = album.image_url
        initialName = album.name
    }

    // need to check whether pinned first, maybe just hold ids of pinned albums in viewModel?
    init(albumID: String, albumName: String, albumImageURL: String) {
        self.albumID = albumID
        initialAlbum = nil
        initialImageURL = albumImageURL
        initialName = albumName
    }

    var body: some View {
        ScrollView {
            if let detail = album ?? initialAlbum {
                detailContent(for: detail)
            } else if isLoading {
                placeholderView(text: "Loading \(initialName)…")
            } else {
                placeholderView(text: "Failed to load album details")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.themeBackground.ignoresSafeArea(edges: .all))
        .navigationTitle(album?.name ?? initialAlbum?.name ?? initialName)
        .navigationBarTitleDisplayMode(.inline)
        .applyDefaultTabBarStyling()
        .task {
            await fetchAlbumIfNeeded()
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func detailContent(for album: AlbumDetail) -> some View {
        HeaderView(for: album)
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: album.artists.count > 1 ? "Artists" : "Artist")
            ForEach(album.artists) { artist in
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
            SectionHeader(title: "Tracks")
            ForEach(album.tracks) { track in
                RowItem(
                    title: "\(track.track_number). \(track.name)",
                    imageURL: album.image_url,
                    clipShape: AnyShape(RoundedRectangle(cornerRadius: 4)),
                    systemImage: "chevron.right"
                ) {
                    SongDetailView(
                        trackID: track.id,
                        imageURL: album.image_url,
                        name: track.name
                    )
                }
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
    fileprivate func HeaderView(for album: AlbumDetail) -> some View {
        VStack(alignment: .center) {
            ZStack {
                CachedAsyncImage(url: URL(string: album.image_url)!)
                    .aspectRatio(contentMode: .fit)
                    .padding(.horizontal, 10)
            }
            .overlay(
                VStack {
                    HStack {
                        Spacer()
                        CircleIconButton(systemName: "arrowshape.turn.up.right") {
                            onOpenSpotifyTapped(album.spotify_uri)
                        }
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        CircleIconButton(
                            systemName: isPinned ? "pin.fill" : "pin"
                        ) {
                            onPinTapped()
                        }
                    }
                }
                .padding(12)
            )
            TwoStatsView(
                leftLabel: "RELEASE DATE",
                leftValue: album.release_date,
                rightLabel: "TOTAL TRACKS",
                rightValue: String(album.total_tracks),
                valueFontSize: .semantic(.title3)
            ).padding(12)
        }
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
        if let loadedID = album?.album_id {
            Task {
                let isDelete = isPinned
                isPinned.toggle()
                let success = await profileViewModel.updatePin(
                    for: loadedID,
                    entity: "album",
                    isDelete: isDelete
                )
                if !success {
                    isPinned.toggle()
                }
            }
        }
    }

    private func fetchAlbumIfNeeded() async {
        let pin = Pin(entity_id: albumID, entity_type: .album)
        isPinned = profileViewModel.isPinned(pin)
        guard album == nil, initialAlbum == nil else {
            return
        }
        isLoading = true
        album = await spotifyViewModel.fetchAlbumDetail(for: albumID)
        isLoading = false
    }
}
