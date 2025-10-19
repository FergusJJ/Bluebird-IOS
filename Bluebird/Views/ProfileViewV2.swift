import SwiftUI

struct ProfileViewV2: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel

    @State private var selectedTrack: SongDetail?
    @State private var selectedAlbum: AlbumDetail?
    @State private var selectedArtist: ArtistDetail?

    @State private var isEditing = false
    @State private var showUnrepostModal = false
    @State private var repostToDelete: Repost?

    var body: some View {
        Group {
            ScrollView {
            VStack(spacing: 0) {
                ProfileHeadlineViewEditable(editableMode: isEditing)

                VStack(spacing: 32) {
                    // Pins section
                    if profileViewModel.pinnedTracks.isEmpty &&
                        profileViewModel.pinnedAlbums.isEmpty &&
                        profileViewModel.pinnedArtists.isEmpty
                    {
                        emptyPinsView()
                    } else {
                        VStack(spacing: 24) {
                            if !profileViewModel.pinnedTracks.isEmpty {
                                pinnedTracksView()
                            }

                            if !profileViewModel.pinnedAlbums.isEmpty {
                                pinnedAlbumsView()
                            }

                            if !profileViewModel.pinnedArtists.isEmpty {
                                pinnedArtistsView()
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }

                    // Reposts section
                    repostsSection()
                        .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.themeBackground.ignoresSafeArea(edges: .all))
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .applyAdaptiveNavigationBar()
        .applyDefaultTabBarStyling()
        .toolbar {
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
        .task {
            logAvatar()
            await profileViewModel.fetchMyReposts()
        }
        .sheet(isPresented: $showUnrepostModal) {
            if let repost = repostToDelete {
                UnrepostConfirmationModal(
                    repost: repost,
                    onConfirm: {
                        Task {
                            let success = await profileViewModel.deleteRepost(postID: repost.post_id)
                            if success {
                                showUnrepostModal = false
                                repostToDelete = nil
                            }
                        }
                    },
                    onCancel: {
                        showUnrepostModal = false
                        repostToDelete = nil
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    @ViewBuilder
    fileprivate func topMilestonesView() -> some View {
        if !profileViewModel.milestones.isEmpty {
            MilestonesPreviewView(
                milestones: profileViewModel.milestones,
                onTap: {
                    // TODO: Navigate to milestones list
                    print("Navigate to milestones")
                }
            )
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    fileprivate func pinnedTracksView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "music.note")
                    .foregroundColor(Color.themeAccent)
                    .font(.headline)
                Text("Pinned Tracks")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.themePrimary)
                Spacer()
            }

            HorizontalScrollSection.tracks(
                title: "",
                items: profileViewModel.pinnedTracks
            ) { track in
                selectedTrack = track
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "square.stack")
                    .foregroundColor(Color.themeAccent)
                    .font(.headline)
                Text("Pinned Albums")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.themePrimary)
                Spacer()
            }

            HorizontalScrollSection.albums(
                title: "",
                items: profileViewModel.pinnedAlbums
            ) { album in
                selectedAlbum = album
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.wave.2")
                    .foregroundColor(Color.themeAccent)
                    .font(.headline)
                Text("Pinned Artists")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.themePrimary)
                Spacer()
            }

            HorizontalScrollSection.artists(
                title: "",
                items: profileViewModel.pinnedArtists
            ) { artist in
                selectedArtist = artist
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

    @ViewBuilder
    fileprivate func emptyPinsView() -> some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.themeElement)
                    .frame(width: 80, height: 80)

                Image(systemName: "pin.slash")
                    .font(.system(size: 35))
                    .foregroundColor(Color.themeSecondary)
            }

            Text("No Pins Yet")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Color.themePrimary)

            Text("Pin your favorite tracks, albums, and artists to showcase them on your profile")
                .font(.subheadline)
                .foregroundColor(Color.themeSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    @ViewBuilder
    fileprivate func repostsSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "arrow.2.squarepath")
                    .foregroundColor(Color.themeAccent)
                    .font(.headline)
                Text("Your Reposts")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.themePrimary)
                Spacer()
            }

            if profileViewModel.isLoadingReposts && profileViewModel.myReposts.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if profileViewModel.myReposts.isEmpty {
                Text("No reposts yet")
                    .font(.subheadline)
                    .foregroundColor(Color.themeSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 16) {
                    ForEach(profileViewModel.myReposts) { repostItem in
                        RepostRowView(
                            repostItem: repostItem,
                            isCurrentUser: true,
                            onEntityTap: {
                                handleRepostEntityTap(repostItem: repostItem)
                            },
                            onProfileTap: {
                                // Current user - do nothing or navigate to own profile
                            },
                            onUnrepostTap: {
                                repostToDelete = repostItem.repost
                                showUnrepostModal = true
                            }
                        )
                    }

                    if !profileViewModel.repostsNextCursor.isEmpty {
                        Button(action: {
                            Task {
                                await profileViewModel.loadMoreReposts()
                            }
                        }) {
                            if profileViewModel.isLoadingReposts {
                                ProgressView()
                            } else {
                                Text("Load More")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.themeAccent)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                }
            }
        }
    }
    

    private func handleRepostEntityTap(repostItem: RepostItem) {
        if let track = repostItem.track_detail {
            selectedTrack = track
        } else if let album = repostItem.album_detail {
            selectedAlbum = album
        } else if let artist = repostItem.artist_detail {
            selectedArtist = artist
        }
    }
    
    func logAvatar() {
        guard let avatar = profileViewModel.avatarURL else {
            print("no avatar")
            return
        }
        print(avatar)
    }
}

