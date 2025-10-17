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

/*

 ---
 Repost Endpoints Specification

 1. Get Current User's Reposts

 GET /api/me/reposts

 Query Parameters:

 | Parameter | Type   | Required | Default | Description                                        |
 |-----------|--------|----------|---------|----------------------------------------------------|
 | cursor    | string | ❌ No     | ""      | Pagination cursor (post_id from previous response) |
 | limit     | number | ❌ No     | 50      | Number of reposts per page (max 50)                |

 Example Requests:
 GET /api/me/reposts
 GET /api/me/reposts?limit=25
 GET /api/me/reposts?cursor=abc-123-def&limit=50

 ---
 2. Get Any User's Reposts

 GET /api/social/users/reposts

 Query Parameters:

 | Parameter | Type   | Required | Default | Description                                        |
 |-----------|--------|----------|---------|----------------------------------------------------|
 | user_id   | string | ✅ Yes    | -       | The user ID whose reposts to fetch                 |
 | cursor    | string | ❌ No     | ""      | Pagination cursor (post_id from previous response) |
 | limit     | number | ❌ No     | 50      | Number of reposts per page (max 50)                |

 Example Requests:
 GET /api/social/users/reposts?user_id=abc-123
 GET /api/social/users/reposts?user_id=abc-123&limit=25
 GET /api/social/users/reposts?user_id=abc-123&cursor=xyz-789&limit=50

 ---
 Response Structure

 {
   reposts: [
     {
       repost: {
         post_id: string,
         profile: {
           user_id: string,
           username: string,
           avatar_url: string,
           bio: string
         },
         entity_type: string,  // "track", "album", or "artist"
         entity_id: string,
         caption: string,
         created_at: string,   // ISO 8601 timestamp
         likes_count: number,
         comments_count: number,
         user_has_liked: boolean
       },
       track_detail: TrackDetail | null,
       album_detail: AlbumDetail | null,
       artist_detail: ArtistDetail | null
     }
     // ... up to 50 entries
   ],
   next_cursor: string  // Empty string if no more pages
 }

 ---
 Example Response

 Track Repost:
 {
   "reposts": [
     {
       "repost": {
         "post_id": "550e8400-e29b-41d4-a716-446655440000",
         "profile": {
           "user_id": "abc-123-def",
           "username": "fergus",
           "avatar_url": "https://project.supabase.co/storage/v1/object/public/avatars/user.jpg",
           "bio": "Music lover"
         },
         "entity_type": "track",
         "entity_id": "3n3Ppam7vgaVa1iaRUc9Lp",
         "caption": "This song is amazing!",
         "created_at": "2025-01-15T14:30:00Z",
         "likes_count": 12,
         "comments_count": 3,
         "user_has_liked": true
       },
       "track_detail": {
         "track_id": "3n3Ppam7vgaVa1iaRUc9Lp",
         "name": "Mr. Brightside",
         "duration_ms": 222973,
         "spotify_url": "https://open.spotify.com/track/3n3Ppam7vgaVa1iaRUc9Lp",
         "album": {...},
         "track_artists": [...]
       },
       "album_detail": null,
       "artist_detail": null
     }
   ],
   "next_cursor": "550e8400-e29b-41d4-a716-446655440000"
 }

 Empty Response:
 {
   "reposts": [],
   "next_cursor": ""
 }

 ---
 Important Notes for iOS Developer

 1. All keys always present: Every field in the response exists (never missing), even if empty/null
 2. Entity details: Based on entity_type, only ONE of these will be non-null:
   - entity_type: "track" → track_detail populated, others null
   - entity_type: "album" → album_detail populated, others null
   - entity_type: "artist" → artist_detail populated, others null
 3. Pagination:
   - First page: omit cursor or use empty string
   - Subsequent pages: use next_cursor from previous response
   - No more pages when next_cursor is empty string ""
   - Cursor is only set if exactly 50 results returned (full page)
 4. Timestamps: All created_at fields use .Truncate(time.Second) for Swift compatibility
 5. Profile info: Includes the user who made the repost (consistent with friends feed structure)
 6. Engagement: user_has_liked is relative to the requesting user, not the repost author

 ---
 Error Responses

 Missing user_id (for /social/users/reposts):
 {
   "errorCode": "MISSING_QUERY",
   "error": "Missing query parameter: user_id"
 }

 */
