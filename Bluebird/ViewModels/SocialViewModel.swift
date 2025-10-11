import SwiftUI

@MainActor
class SocialViewModel: ObservableObject {
    private var appState: AppState

    @Published var friendsCurrentlyPlaying: [String: SongDetail] = [:]

    private let bluebirdAccountAPIService: BluebirdAccountAPIService
    init(
        appState: AppState,
        bluebirdAccountAPIService: BluebirdAccountAPIService
    ) {
        self.appState = appState
        self.bluebirdAccountAPIService = bluebirdAccountAPIService
    }

    func fetchFriendsCurrentlyPlaying() async {
        let result = await bluebirdAccountAPIService.getFriendsCurrentlyPlaying(
            for: [])
        switch result {
        case let .success(userIDTrackMap):
            await MainActor.run {
                friendsCurrentlyPlaying = userIDTrackMap
            }
            print(
                "Updated currently playing for \(userIDTrackMap.count) friends"
            )
            print(friendsCurrentlyPlaying)

        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error refreshing history: \(presentationError)")
            appState.setError(presentationError)
        }
    }

    // want a way to get the users' friends currenlty playing
    // then want to show reposts.

    // Reposts:
    // Need to query the reposts of all friends.
    // then can return the details back for each repost,
    // alongside data such as:
    // timestamp, who reposted, caption?
    // make easy to extend via comments, not sure abvout this yet
    // Strategy: maybe fetch all reposts in the past x days? Limit by some amount of number?
    // But want to show all posts so maybe read all
    // then send back x, and allow pagination?

    // Currently playing:
    // Maybe going to want to cache the users access token when they are on the app so we don't keep on wiping it?
    // and if not in cache just get new one?
    // access tokens aren't invalidated when a new one is issued.
}
