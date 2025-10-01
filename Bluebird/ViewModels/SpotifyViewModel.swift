import Combine
import Foundation
import SwiftUI

@MainActor
class SpotifyViewModel: ObservableObject {
    @Published var currentlyPlaying: SongDetail?
    @Published var songHistory: [Int: SongDetail] = [:]

    @Published var isLoading: Bool = false
    @Published var canLoadMore: Bool = true

    private var appState: AppState
    private let spotifyAPIService: SpotifyAPIService

    var sortedSongs: [SongDetail] {
        songHistory.values.sorted { $0.listened_at! > $1.listened_at! }
    }

    init(appState: AppState, spotifyAPIService: SpotifyAPIService) {
        self.appState = appState
        self.spotifyAPIService = spotifyAPIService
    }

    func loadCurrentlyPlaying() async {
        guard let accessToken = appState.getSpotifyAccessToken() else {
            print("Load currently playing failed: Access token is nil.")
            currentlyPlaying = nil
            return
        }

        let result = await spotifyAPIService.getCurrentlyPlaying(
            spotifyAccessToken: accessToken
        )

        switch result {
        case let .success(response):
            guard let songData = response else {
                currentlyPlaying = nil
                return
            }
            appState.currentSong = songData.name
            appState.currentArtist = songData.artists.map { $0.name }.joined(
                separator: ", "
            )
            currentlyPlaying = songData
        case let .failure(serviceError):
            currentlyPlaying = nil
            let presentationError = AppError(from: serviceError)
            print("Error loading currently playing: \(presentationError)")
        }
    }

    func refreshHistory() async {
        guard let accessToken = appState.getSpotifyAccessToken() else {
            print("Refresh failed: Access token is nil.")
            return
        }

        let result = await spotifyAPIService.getSongHistory(
            spotifyAccessToken: accessToken,
        )

        switch result {
        case let .success(songArray):
            guard !songArray.isEmpty else {
                print("Refresh check: No new songs found.")
                return
            }

            print("Refreshed and found \(songArray.count) new songs.")
            print("first: \(songArray.first!.name)")
            print("last: \(songArray.last!.name)")
            let newSongs = Dictionary(
                songArray.map { ($0.listened_at!, $0) },
                uniquingKeysWith: { first, _ in first }
            )
            songHistory.merge(newSongs) { existing, _ in existing }

        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error refreshing history: \(presentationError)")
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

        let result = await spotifyAPIService.getSongHistoryPaginate(
            before: oldestTimestamp
        )

        switch result {
        case let .success(songArray):
            print("Fetched \(songArray.count) older songs.")

            if songArray.isEmpty {
                canLoadMore = false
                return
            }
            let newSongs = Dictionary(
                songArray.map { ($0.listened_at!, $0) },
                uniquingKeysWith: { first, _ in first }
            )
            songHistory.merge(newSongs) { existing, _ in existing }

        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error fetching older history: \(presentationError)")
        }
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
        let result = await spotifyAPIService.getArtistDetail(
            spotifyAccessToken: accessToken,
            id: artistID
        )
        switch result {
        case let .success(artistDetail):
            return artistDetail
        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error fetching artist detail: \(presentationError)")
            return nil
        }
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
        let result = await spotifyAPIService.getSongDetail(
            spotifyAccessToken: accessToken,
            id: songID
        )
        switch result {
        case let .success(artistDetail):
            return artistDetail
        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error fetching song detail: \(presentationError)")
            return nil
        }
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
        let result = await spotifyAPIService.getAlbumDetail(
            spotifyAccessToken: accessToken,
            id: albumID
        )
        switch result {
        case let .success(albumDetail):
            return albumDetail
        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error fetching album detail: \(presentationError)")
            return nil
        }
    }
}
