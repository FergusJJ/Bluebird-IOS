import Combine
import Foundation
import SwiftUI

@MainActor
class SpotifyViewModel: ObservableObject, TryRequestViewModel {
    @Published var currentlyPlaying: SongDetail?
    @Published var songHistory: [Int: SongDetail] = [:]

    @Published var isLoading: Bool = false
    @Published var canLoadMore: Bool = true

    internal var appState: AppState
    private let spotifyAPIService: SpotifyAPIService
    private let cacheManager = CacheManager.shared

    var sortedSongs: [SongDetail] {
        songHistory.values.sorted { $0.listened_at! > $1.listened_at! }
    }

    init(appState: AppState, spotifyAPIService: SpotifyAPIService) {
        self.appState = appState
        self.spotifyAPIService = spotifyAPIService
        loadCachedHistory()
    }

    private func loadCachedHistory() {
        songHistory = cacheManager.getSongHistory()
        print("Loaded \(songHistory.count) songs from cache")
    }

    func isCacheStale() -> Bool {
        guard let lastUpdated = cacheManager.getSongHistoryLastUpdated() else {
            return true // No cache, treat as stale
        }

        // Cache is stale if older than 1 hour
        let cacheAge = Date().timeIntervalSince(lastUpdated)
        let oneHour: TimeInterval = 3600
        return cacheAge > oneHour
    }

    func loadCurrentlyPlaying() async {
        guard let accessToken = appState.getSpotifyAccessToken() else {
            print("Load currently playing failed: Access token is nil.")
            currentlyPlaying = nil
            return
        }

        if let songData = await tryRequest(
            { await spotifyAPIService.getCurrentlyPlaying(spotifyAccessToken: accessToken) },
            "Error fetching currently playing"
        ) {
            if songData.isEmpty {
                currentlyPlaying = nil
                return
            }
            appState.currentSong = songData.name
            appState.currentArtist = songData.artists.map { $0.name }.joined(
                separator: ", "
            )
            currentlyPlaying = songData
        } else {
            currentlyPlaying = nil
        }
    }

    func refreshHistory() async {
        guard let accessToken = appState.getSpotifyAccessToken() else {
            print("Refresh failed: Access token is nil.")
            return
        }

        if let songArray = await tryRequest(
            { await spotifyAPIService.getSongHistory(spotifyAccessToken: accessToken) },
            "Error fetching song history"
        ) {
            guard !songArray.isEmpty else {
                return
            }

            let newSongs = Dictionary(
                songArray.map { ($0.listened_at!, $0) },
                uniquingKeysWith: { first, _ in first }
            )
            songHistory.merge(newSongs) { existing, _ in existing }
            cacheManager.saveSongHistory(songHistory)
        }
    }

    func fetchOlderPlaysHistory() async {
        guard !isLoading, canLoadMore else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        guard let oldestTimestamp = songHistory.keys.min() else {
            print(
                "Cannot paginate further, history is empty or not yet loaded."
            )
            canLoadMore = false
            return
        }

        if let songArray = await tryRequest(
            { await spotifyAPIService.getSongHistoryPaginate(before: oldestTimestamp) },
            "Error fetching older song history"
        ) {
            if songArray.isEmpty {
                canLoadMore = false
                return
            }
            let newSongs = Dictionary(
                songArray.map { ($0.listened_at!, $0) },
                uniquingKeysWith: { first, _ in first }
            )
            songHistory.merge(newSongs) { existing, _ in existing }
            cacheManager.saveSongHistory(songHistory)
        }
    }

    func clearHistory() {
        songHistory.removeAll()
        currentlyPlaying = nil
        canLoadMore = true
    }

    func fetchArtistDetail(for artistID: String) async -> ArtistDetail? {
        guard let accessToken = appState.getSpotifyAccessToken() else {
            print("Refresh failed: Access token is nil.")
            return nil
        }
        guard !isLoading else {
            return nil
        }
        defer {
            isLoading = false
        }
        isLoading = true

        return await tryRequest(
            { await spotifyAPIService.getArtistDetail(spotifyAccessToken: accessToken, id: artistID) },
            "Error fetching artist detail"
        )
    }

    func fetchSongDetail(for songID: String) async -> SongDetail? {
        guard let accessToken = appState.getSpotifyAccessToken() else {
            print("Refresh failed: Access token is nil.")
            return nil
        }
        guard !isLoading else {
            return nil
        }
        defer {
            isLoading = false
        }
        isLoading = true

        return await tryRequest(
            { await spotifyAPIService.getSongDetail(spotifyAccessToken: accessToken, id: songID) },
            "Error fetching song detail"
        )
    }

    func fetchAlbumDetail(for albumID: String) async -> AlbumDetail? {
        guard let accessToken = appState.getSpotifyAccessToken() else {
            print("Refresh failed: Access token is nil.")
            return nil
        }
        guard !isLoading else {
            return nil
        }
        defer {
            isLoading = false
        }
        isLoading = true

        return await tryRequest(
            { await spotifyAPIService.getAlbumDetail(spotifyAccessToken: accessToken, id: albumID) },
            "Error fetching album detail"
        )
    }
}
