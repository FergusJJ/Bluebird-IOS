import Combine
import Foundation
import SwiftUI

@MainActor
class SpotifyViewModel: ObservableObject {
    @Published var currentlyPlaying: ViewSong?
    @Published var songHistory: [Int: ViewSongExt] = [:]

    @Published var isLoading: Bool = false
    @Published var canLoadMore: Bool = true

    private var appState: AppState
    private let spotifyAPIService: SpotifyAPIService

    var sortedSongs: [ViewSongExt] {
        songHistory.values.sorted { $0.listenedAt > $1.listenedAt }
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

        let result = await spotifyAPIService.getCurrentlyPlaying(spotifyAccessToken: accessToken)

        switch result {
        case let .success(response):
            guard let songData = response else {
                currentlyPlaying = nil
                return
            }
            currentlyPlaying = ViewSong(
                song: songData.trackName,
                artists: songData.artistNames,
                imageUrl: songData.imageUrl
            )
        case let .failure(serviceError):
            currentlyPlaying = nil
            let presentationError = AppError(from: serviceError)
            print("Error loading currently playing: \(presentationError)")
        }
    }

    /// Fetches the latest songs, intended for pull-to-refresh or initial load.
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
            print("first: \(songArray.first!.trackName)")
            print("last: \(songArray.last!.trackName)")
            let newSongs = Dictionary(uniqueKeysWithValues: songArray.map { ($0.listenedAt, $0) })
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
            print("Cannot paginate further, history is empty or not yet loaded.")
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

            let newSongs = Dictionary(uniqueKeysWithValues: songArray.map { ($0.listenedAt, $0) })
            songHistory.merge(newSongs) { existing, _ in existing }

        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error fetching older history: \(presentationError)")
        }
    }
}
