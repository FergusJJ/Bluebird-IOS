import SwiftUI

struct SongDetailView: View {
    let trackID: String
    let initialSong: SongDetail?
    let initialImageURL: String
    let initialName: String

    @State private var song: SongDetail?
    @State private var isLoading = false
    @State private var isPinned = false

    @EnvironmentObject var spotifyViewModel: SpotifyViewModel

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
        .background(Color.darkBackground.ignoresSafeArea(edges: .all))
        .navigationTitle(song?.name ?? initialSong?.name ?? initialName)
        .navigationBarTitleDisplayMode(.inline)
        .applyDefaultTabBarStyling()
        .task {
            await fetchSongIfNeeded()
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func detailContent(for song: SongDetail) -> some View {
        /* VStack(alignment: .center) {
             ZStack(alignment: .bottomTrailing) {
                 CachedAsyncImage(url: URL(string: song.album_image_url)!)
                     .aspectRatio(contentMode: .fit)
                     .padding(.horizontal, 10)

                 Button {
                     isPinned.toggle()
                     onPinTapped()
                 } label: {
                     Image(systemName: isPinned ? "pin.fill" : "pin")
                         .font(.title2)
                         .padding(8)
                         .background(Color.black.opacity(0.6))
                         .clipShape(Circle())
                         .foregroundStyle(.white)
                         .padding([.trailing, .bottom], 12)
                 }
             }
         } */
        HeaderView(for: song)

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
        Divider()
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
        let spotifyURL = URL(string: uri.replacingOccurrences(of: "spotify:", with: "spotify://"))!
        if UIApplication.shared.canOpenURL(spotifyURL) {
            UIApplication.shared.open(spotifyURL, options: [:], completionHandler: nil)
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
                HStack {
                    Spacer()
                    CircleIconButton(systemName: "arrowshape.turn.up.right") {
                        onOpenSpotifyTapped(song.spotify_url)
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
        .background(Color.darkBackground.ignoresSafeArea(edges: .all))
    }

    private func onPinTapped() {
        print("Pinning track \(trackID)")
    }

    private func fetchSongIfNeeded() async {
        guard song == nil, initialSong == nil else { return }
        isLoading = true
        song = await spotifyViewModel.fetchSongDetail(for: trackID)
        isLoading = false
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(Color.nearWhite.opacity(0.9))
                .padding(.horizontal, 16)
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.nearWhite.opacity(0.2))
                .padding(.horizontal, 16)
        }
        .padding(.top, 16)
    }
}
