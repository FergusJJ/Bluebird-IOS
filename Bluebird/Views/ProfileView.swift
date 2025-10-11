import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel

    let isCurrentUser: Bool

    @State private var selectedTrack: SongDetail?
    @State private var selectedAlbum: AlbumDetail?
    @State private var selectedArtist: ArtistDetail?

    @State private var isEditing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isCurrentUser {
                    ProfileHeadlineViewEditable(editableMode: isEditing)
                } else {
                    ProfileHeadlineView()
                }
                Divider()
                VStack {
                    pinnedTracksView()
                    Divider()
                    pinnedAlbumsView()
                    Divider()
                    pinnedArtistsView()
                    Divider()
                }
                .padding()
                .cornerRadius(10)
                .padding(.horizontal)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.themeBackground.ignoresSafeArea(edges: .all))
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .applyDefaultTabBarStyling()
        .toolbar {
            if isCurrentUser {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isEditing.toggle() }) {
                        Image(systemName: isEditing ? "pencil.line" : "pencil")
                            .foregroundColor(Color.themeAccent)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(Color.themeAccent)
                    }
                }
            }
        }
    }

    @ViewBuilder
    fileprivate func pinnedTracksView() -> some View {
        VStack {
            if profileViewModel.pinnedTracks.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Your Pinned Tracks")
                        .foregroundStyle(Color.themePrimary)
                        .font(.subheadline)

                    Text("Nothing to see here.")
                        .foregroundStyle(Color.themePrimary.opacity(0.6))
                        .font(.caption)
                        .padding(.vertical, 10)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            } else {
                HorizontalScrollSection.tracks(
                    title: "Your Pinned Tracks",
                    items: profileViewModel.pinnedTracks
                ) { track in
                    selectedTrack = track
                }
                .padding(.horizontal)
            }
        }
        .navigationDestination(item: $selectedTrack) { track in
            SongDetailView(
                trackID: track.track_id,
                imageURL: track.album_image_url,
                name: track.name
            )
        }
    }

    @ViewBuilder
    fileprivate func pinnedAlbumsView() -> some View {
        VStack {
            if profileViewModel.pinnedAlbums.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Your Pinned Albums")
                        .foregroundStyle(Color.themePrimary)
                        .font(.subheadline)

                    Text("Nothing to see here.")
                        .foregroundStyle(Color.themePrimary.opacity(0.6))
                        .font(.caption)
                        .padding(.vertical, 10)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            } else {
                HorizontalScrollSection.albums(
                    title: "Your Pinned Albums",
                    items: profileViewModel.pinnedAlbums
                ) { album in
                    selectedAlbum = album
                }
                .padding(.horizontal)
            }
        }
        .navigationDestination(item: $selectedAlbum) { album in
            AlbumDetailView(
                albumID: album.album_id,
                albumName: album.name,
                albumImageURL: album.image_url
            )
        }
    }

    @ViewBuilder
    fileprivate func pinnedArtistsView() -> some View {
        VStack {
            if profileViewModel.pinnedArtists.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Your Pinned Artists")
                        .foregroundStyle(Color.themePrimary)
                        .font(.subheadline)

                    Text("Nothing to see here.")
                        .foregroundStyle(Color.themePrimary.opacity(0.6))
                        .font(.caption)
                        .padding(.vertical, 10)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            } else {
                HorizontalScrollSection.artists(
                    title: "Your Pinned Artists",
                    items: profileViewModel.pinnedArtists
                ) { artist in
                    selectedArtist = artist
                }
                .padding(.horizontal)
            }
        }
        .navigationDestination(item: $selectedArtist) { artist in
            ArtistDetailView(
                artist: SongDetailArtist(
                    id: artist.artist_id,
                    image_url: artist.spotify_uri,
                    name: artist.name
                )
            )
        }
    }
}
