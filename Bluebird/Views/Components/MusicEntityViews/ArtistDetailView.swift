import SwiftUI

struct ArtistDetailView: View {
    let artist: SongDetailArtist
    @State private var isPinned = false
    @State private var artistDetail: ArtistDetail?
    @EnvironmentObject var spotifyViewModel: SpotifyViewModel

    @State private var selectedTrack: TopTrack?
    @State private var selectedAlbum: AlbumSummary?
    @State private var navigateToSongDetail = false

    var body: some View {
        ScrollView {
            VStack(alignment: .center) {
                artistHeaderView()
                Divider()
                ArtistStats(totalFollowers: artistDetail?.followers,
                            userListens: nil)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                Divider()
                topTracksSection()
                albumsSection()
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.darkBackground.ignoresSafeArea(edges: .all))
        .navigationTitle(artist.name)
        .navigationBarTitleDisplayMode(.inline)
        .applyDefaultTabBarStyling()
        .task {
            await fetchData()
        }
    }

    private func onPinTapped() {
        print("Pinning artist")
        // Add pinning logic here
    }

    private func onOpenSpotifyTapped(_ uri: String) {
        let spotifyURL = URL(string: uri.replacingOccurrences(of: "spotify:", with: "spotify://"))!
        if UIApplication.shared.canOpenURL(spotifyURL) {
            UIApplication.shared.open(spotifyURL, options: [:], completionHandler: nil)
        }
    }

    private func fetchData() async {
        artistDetail = await spotifyViewModel.fetchArtistDetail(for: artist.id)
    }
}

// MARK: - UI Helper Views

private extension ArtistDetailView {
    @ViewBuilder
    func artistHeaderView() -> some View {
        ZStack {
            CachedAsyncImage(url: URL(string: artist.image_url)!)
                .aspectRatio(contentMode: .fit)
                .clipShape(Circle())
                .padding(40)
        }
        .overlay(
            VStack {
                HStack {
                    Spacer()
                    if let uri = artistDetail?.spotify_uri {
                        CircleIconButton(systemName: "arrowshape.turn.up.right") {
                            onOpenSpotifyTapped(uri)
                        }
                    }
                }
                Spacer()
                HStack {
                    Spacer()
                    CircleIconButton(systemName: isPinned ? "pin.fill" : "pin") {
                        isPinned.toggle()
                        onPinTapped()
                    }
                }
            }
            .padding(12)
        )
    }

    @ViewBuilder
    func topTracksSection() -> some View {
        if let topTracks = artistDetail?.top_tracks, !topTracks.isEmpty {
            VStack {
                HorizontalScrollSection.tracks(
                    title: "Top Tracks",
                    items: topTracks
                ) { track in
                    selectedTrack = track
                }
                .padding(.horizontal)
            }
            .navigationDestination(item: $selectedTrack) { track in
                SongDetailView(
                    trackID: track.id,
                    imageURL: track.image_url,
                    name: track.name
                )
            }
            Divider()
        }
    }

    @ViewBuilder
    func albumsSection() -> some View {
        if let albums = artistDetail?.albums, !albums.isEmpty {
            VStack {
                HorizontalScrollSection.albums(
                    title: "Albums",
                    items: albums
                ) { album in
                    print("Selected album: \(album.name)")
                    selectedAlbum = album
                }
                .padding(.horizontal)
            }
            .navigationDestination(item: $selectedAlbum) { album in
                AlbumDetailView(
                    albumID: album.album_id, albumName: album.name, albumImageURL: album.image_url
                )
            }
            .padding(.horizontal)
            Divider()
        }
    }
}
