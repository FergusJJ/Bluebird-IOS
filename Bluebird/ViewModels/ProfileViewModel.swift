import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    // may want to add stuff here for all time song plays/number of artists listened to etc.
    // but not sure how/where im going to store that yet

    // MARK: - User profile vars

    private let numDays = 14

    @Published var username: String = ""
    @Published var bio: String = ""
    @Published var avatarPath = ""
    @Published var avatarURL: URL?
    @Published var selectedImage: UIImage?

    // MARK: - User stats vars

    @Published var totalMinutesListened: Int = 0
    @Published var totalPlays: Int = 0
    @Published var totalUniqueArtists: Int = 0

    // TODO: probably want sets containing pinned IDs for entities for lookup?
    //   will store the displayed stuff separately

    // MARK: extra

    @Published var searchQuery: String = ""

    @Published var isLoading = false

    // MARK: - Pins

    @Published private(set) var orderedPins: [Pin] = []
    private var pinsById: [String: Pin] = [:]

    // local cache
    private var pinnedArtistDetails: [String: ArtistDetail] = [:]
    private var pinnedTrackDetails: [String: SongDetail] = [:]
    private var pinnedAlbumDetails: [String: AlbumDetail] = [:]

    // UI object
    @Published var pinnedArtists: [ArtistDetail] = []
    @Published var pinnedTracks: [SongDetail] = []
    @Published var pinnedAlbums: [AlbumDetail] = []

    // MARK: - settings page stuff

    @Published var connectedAccountDetails: ConnectedAccountDetails?

    @State var pinsFetched = false

    private var appState: AppState

    private let bluebirdAccountAPIService: BluebirdAccountAPIService
    private let supabaseManager = SupabaseClientManager.shared

    init(
        appState: AppState,
        bluebirdAccountAPIService: BluebirdAccountAPIService
    ) {
        self.appState = appState
        self.bluebirdAccountAPIService = bluebirdAccountAPIService
        Task {
            guard appState.isLoggedIn == .istrue else {
                return
            }
            await syncAllPinnedContent()
            pinsFetched = true
        }
    }

    func getCurrentlyPlayingHeadline() -> String {
        return "\(appState.currentSong) - \(appState.currentArtist)"
    }

    func loadProfile() async {
        let result = await bluebirdAccountAPIService.getProfile()
        switch result {
        case let .success(profileInfo):
            username = profileInfo.username
            bio = profileInfo.bio
            avatarURL = URL(string: profileInfo.avatarUrl)
        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error loading profile info: \(presentationError)")
            appState.setError(presentationError)
        }
    }

    func loadHeadlineStats() async {
        let result = await bluebirdAccountAPIService.getHeadlineStats(for: numDays)
        switch result {
        case let .success(stats):
            totalPlays = stats.total_plays
            totalUniqueArtists = stats.unique_artists
            totalMinutesListened = (stats.total_duration_millis / (60 * 1000))
        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error loading headline stats info: \(presentationError)")
            appState.setError(presentationError)
        }
    }

    func updateUserBio(with bio: String) async -> Bool {
        if isLoading {
            return false
        }
        let oldBio = self.bio
        self.bio = bio

        let success = await updateProfile(
            username: nil,
            bio: bio,
            avatarPath: nil
        )
        if !success {
            self.bio = oldBio
        }
        return success
    }

    // TODO: to think about/add deletions too, so maybe UIImage should be optional
    func updateProfilePicture(with image: UIImage) async -> Bool {
        if isLoading {
            return false
        }

        isLoading = true
        selectedImage = image
        let oldAvatarURL = avatarURL
        defer {
            isLoading = false
            selectedImage = nil
        }

        let result = await supabaseManager.uploadAvatar(avatar: image)

        guard case let .success(fileName) = result else {
            if case let .failure(error) = result {
                if let supabaseError = error as? SupabaseError {
                    let presentationError = AppError(from: supabaseError)
                    print(
                        "A Supabase-specific error occurred: \(presentationError.localizedDescription)"
                    )
                    appState.setError(presentationError)
                } else {
                    print(
                        "A generic error occurred: \(error.localizedDescription)"
                    )
                    let presentationError = AppError.genericSupabaseError
                    appState.setError(presentationError)
                }
            }
            avatarURL = oldAvatarURL
            return false
        }

        let updateSuccess = await updateProfile(
            username: nil,
            bio: nil,
            avatarPath: fileName
        )
        if updateSuccess {
            avatarURL = supabaseManager.getAvatarUrl(for: fileName)
            return true
        } else {
            // TODO: Add logic to delete orphaned avatar URL?
            avatarURL = oldAvatarURL
            return false
        }
    }

    // MARK: - Settings page

    func fetchConnectedSpotifyDetails() async {
        guard let spotifyAccessToken = appState.getSpotifyAccessToken() else {
            print("FetchConnectedSpotifyDetails failed: Access token is nil.")
            return
        }
        let res = await bluebirdAccountAPIService.getConnectedAccountDetail(accessToken: spotifyAccessToken)
        switch res {
        case let .success(details):
            connectedAccountDetails = details
        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print(
                "An API error occurred: \(presentationError.localizedDescription)"
            )
            appState.setError(presentationError)
        }
    }

    func logOut() async {
        _ = await appState.logoutUser()
    }

    func deleteAccount() async {
        _ = await appState.deleteUser()
    }

    // MARK: - Pins

    func updatePin(for id: String, entity: String, isDelete: Bool) async -> Bool {
        if isLoading {
            return false
        }
        isLoading = true
        defer {
            isLoading = false
        }
        guard let entityType = EntityType(safeRawValue: entity) else {
            print("updatePin failed: Invalid entity type: '\(entity)'")
            return false
        }
        guard let spotifyAccessToken = appState.getSpotifyAccessToken() else {
            print("updatePin failed: Access token is nil.")
            return false
        }

        let result = await bluebirdAccountAPIService.updatePin(
            accessToken: spotifyAccessToken,
            id: id,
            entity: entityType,
            isDelete: isDelete
        )
        switch result {
        case .success():
            guard let entityType = EntityType(safeRawValue: entity) else {
                print("Invalid entity type received from server: \(entity)")
                return true
            }
            if isDelete {
                removePin(Pin(entity_id: id, entity_type: entityType))
                // Remove from local cache based on entity type
                switch entityType {
                case .track:
                    pinnedTrackDetails.removeValue(forKey: id)
                case .album:
                    pinnedAlbumDetails.removeValue(forKey: id)
                case .artist:
                    pinnedArtistDetails.removeValue(forKey: id)
                }
            } else {
                addPin(Pin(entity_id: id, entity_type: entityType))
                await fetchDetailsForNewPin(id: id, entityType: entityType)
            }
            // Update UI arrays after pin change
            updateAllUIArrays()
            return true
        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print(
                "An API error occurred: \(presentationError.localizedDescription)"
            )
            appState.setError(presentationError)
            return false
        }
    }

    private func getPins(entities: [String]) async -> Bool {
        if isLoading {
            return false
        }
        isLoading = true
        defer {
            isLoading = false
        }
        let stringQuery = entities.joined(separator: ",")
        let result = await bluebirdAccountAPIService.getPins(query: stringQuery)
        switch result {
        case let .success(getPinsResult):
            print("Got \(getPinsResult.total) pins")
            orderedPins.removeAll()
            pinsById.removeAll()
            for pin in getPinsResult.pins {
                addPin(pin)
            }
            return true
        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print(
                "An API error occurred fetching pins: \(presentationError.localizedDescription)"
            )
            appState.setError(presentationError)
            return false
        }
    }

    private func updateProfile(
        username: String?,
        bio: String?,
        avatarPath: String?
    ) async -> Bool {
        guard username != nil || bio != nil || avatarPath != nil else {
            print("Error: At least one profile attribute must be provided.")
            return false
        }
        let result = await bluebirdAccountAPIService.updateProfile(
            username: username,
            bio: bio,
            avatarPath: avatarPath
        )
        switch result {
        case .success():
            print("Successfully update profile info!")
            return true
        // probably want some ui feedback here like a popup
        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print(
                "An API error occurred: \(presentationError.localizedDescription)"
            )
            appState.setError(presentationError)
            return false
        }
    }

    // MARK: - Sync Logic

    func syncAllPinnedContent() async {
        let success = await getPins(entities: ["artist", "album", "track"])
        guard success else {
            print("Failed to fetch pins")
            return
        }
        await syncPinnedTracks()
        await syncPinnedAlbums()
        await syncPinnedArtists()
    }

    func syncPinnedTracks() async {
        let newTrackIDs = Set(
            orderedPins.filter { $0.entity_type == .track }.map { $0.entity_id }
        )
        let localTrackIDs = Set(pinnedTrackDetails.keys)
        let trackIDsToAdd = newTrackIDs.subtracting(localTrackIDs)
        let trackIDsToRemove = localTrackIDs.subtracting(newTrackIDs)
        for trackID in trackIDsToRemove {
            pinnedTrackDetails.removeValue(forKey: trackID)
        }
        if !trackIDsToAdd.isEmpty {
            await fetchAndCacheTrackDetails(trackIDs: Array(trackIDsToAdd))
        }

        updatePinnedTracksUIArray()
    }

    func syncPinnedAlbums() async {
        let newAlbumIDs = Set(
            orderedPins.filter { $0.entity_type == .album }.map { $0.entity_id }
        )
        let localAlbumIDs = Set(pinnedAlbumDetails.keys)
        let albumIDsToAdd = newAlbumIDs.subtracting(localAlbumIDs)
        let albumIDsToRemove = localAlbumIDs.subtracting(newAlbumIDs)
        for albumID in albumIDsToRemove {
            pinnedAlbumDetails.removeValue(forKey: albumID)
        }
        if !albumIDsToAdd.isEmpty {
            await fetchAndCacheAlbumDetails(albumIDs: Array(albumIDsToAdd))
        }

        updatePinnedAlbumsUIArray()
    }

    func syncPinnedArtists() async {
        let newArtistIDs = Set(
            orderedPins.filter { $0.entity_type == .artist }.map {
                $0.entity_id
            }
        )
        let localArtistIDs = Set(pinnedArtistDetails.keys)
        let artistIDsToAdd = newArtistIDs.subtracting(localArtistIDs)
        let artistIDsToRemove = localArtistIDs.subtracting(newArtistIDs)
        for artistID in artistIDsToRemove {
            pinnedArtistDetails.removeValue(forKey: artistID)
        }
        if !artistIDsToAdd.isEmpty {
            await fetchAndCacheArtistDetails(artistIDs: Array(artistIDsToAdd))
        }

        updatePinnedArtistsUIArray()
    }

    // MARK: - Fetch and Cache Methods

    private func fetchAndCacheTrackDetails(trackIDs: [String]) async {
        let res = await bluebirdAccountAPIService.getEntityDetails(
            trackIDs: trackIDs,
            albumIDs: [],
            artistIDs: []
        )

        switch res {
        case let .success(getEntityResponse):
            for trackDetail in getEntityResponse.tracks {
                pinnedTrackDetails[trackDetail.track_id] = trackDetail
            }

        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error loading track details: \(presentationError)")
            appState.setError(presentationError)
        }
    }

    private func fetchAndCacheAlbumDetails(albumIDs: [String]) async {
        let res = await bluebirdAccountAPIService.getEntityDetails(
            trackIDs: [],
            albumIDs: albumIDs,
            artistIDs: []
        )

        switch res {
        case let .success(getEntityResponse):
            for albumDetail in getEntityResponse.albums {
                pinnedAlbumDetails[albumDetail.album_id] = albumDetail
            }

        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error loading album details: \(presentationError)")
            appState.setError(presentationError)
        }
    }

    private func fetchAndCacheArtistDetails(artistIDs: [String]) async {
        let res = await bluebirdAccountAPIService.getEntityDetails(
            trackIDs: [],
            albumIDs: [],
            artistIDs: artistIDs
        )

        switch res {
        case let .success(getEntityResponse):
            for artistDetail in getEntityResponse.artists {
                pinnedArtistDetails[artistDetail.artist_id] = artistDetail
            }

        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error loading artist details: \(presentationError)")
            appState.setError(presentationError)
        }
    }

    private func fetchDetailsForNewPin(id: String, entityType: EntityType) async {
        switch entityType {
        case .track:
            await fetchAndCacheTrackDetails(trackIDs: [id])
        case .album:
            await fetchAndCacheAlbumDetails(albumIDs: [id])
        case .artist:
            await fetchAndCacheArtistDetails(artistIDs: [id])
        }
    }

    // MARK: - UI Array Updates

    private func updatePinnedTracksUIArray() {
        pinnedTracks =
            orderedPins
                .filter { $0.entity_type == .track }
                .compactMap { pin in
                    pinnedTrackDetails[pin.entity_id]
                }
    }

    private func updatePinnedAlbumsUIArray() {
        pinnedAlbums =
            orderedPins
                .filter { $0.entity_type == .album }
                .compactMap { pin in
                    pinnedAlbumDetails[pin.entity_id]
                }
    }

    private func updatePinnedArtistsUIArray() {
        pinnedArtists =
            orderedPins
                .filter { $0.entity_type == .artist }
                .compactMap { pin in
                    pinnedArtistDetails[pin.entity_id]
                }
    }

    private func updateAllUIArrays() {
        updatePinnedTracksUIArray()
        updatePinnedAlbumsUIArray()
        updatePinnedArtistsUIArray()
    }

    func isPinned(_ pin: Pin) -> Bool {
        return pinsById[pin.id] != nil
    }

    private func addPin(_ pin: Pin) {
        guard pinsById[pin.id] == nil else { return }
        pinsById[pin.id] = pin
        orderedPins.append(pin)
    }

    private func removePin(_ pin: Pin) {
        pinsById[pin.id] = nil
        orderedPins.removeAll { $0.id == pin.id }
    }
}
