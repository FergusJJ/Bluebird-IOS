import SwiftUI

@MainActor
class SpotifyViewModel: ObservableObject {
    @Published var currentlyPlaying: ViewSong?

    private let spotifyAPIService: SpotifyAPIService

    init(spotifyAPIService: SpotifyAPIService) {
        self.spotifyAPIService = spotifyAPIService
    }

    // don't think this should ever throw, should just either update UI or
    func loadCurrentlyPlaying(spotifyAccessToken: String?) async {
        // this should never happen
        guard let accessToken = spotifyAccessToken else {
            print("error no spotifyAppToken")
            return
        }
        let result = await spotifyAPIService.getCurrentlyPlaying(spotifyAccessToken: accessToken)
        // TODO:
        switch result {
        case let .success(response):
            print("success")
            guard let songData = response else {
                currentlyPlaying = nil
                return
            }
            currentlyPlaying = ViewSong(
                song: songData.trackName,
                artists: songData.artistNames.joined(separator: ", "),
                imageUrl: songData.imageUrl,
            )

        case let .failure(serviceError):
            // this needs to use APIError from bluebirderror
            currentlyPlaying = nil
            let presentationError = APIError(from: serviceError)
            // want some modal to show an error, dont want an error screen
            // because info might still be on there, i.e. song history that was
            // fetched earlier

            print("error \(presentationError)")
        }
    }
}
