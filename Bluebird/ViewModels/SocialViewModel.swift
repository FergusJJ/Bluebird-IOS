import SwiftUI

@MainActor
class SocialViewModel: ObservableObject {
    private var appState: AppState

    @Published var currentUserProfile: UserProfileDetail?
    @Published var friendsCurrentlyPlaying: [String: FriendCurrentlyPlaying] =
        [:]

    private var userProfileDetailCache:
        [String: (profile: UserProfileDetail, timestamp: Date)] = [:]

    private let bluebirdAccountAPIService: BluebirdAccountAPIService
    init(
        appState: AppState,
        bluebirdAccountAPIService: BluebirdAccountAPIService
    ) {
        self.appState = appState
        self.bluebirdAccountAPIService = bluebirdAccountAPIService
    }

    func fetchUserProfile(userId: String, forceRefresh: Bool) async {
        if !forceRefresh,
           let cached = userProfileDetailCache[userId],
           Date().timeIntervalSince(cached.timestamp) < 300
        {
            currentUserProfile = cached.profile
            return
        }
        let result = await bluebirdAccountAPIService.getUser(userID: userId)
        switch result {
        case let .success(profileDetail):
            userProfileDetailCache[userId] = (profileDetail, Date())
            currentUserProfile = profileDetail

        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error fetching user profile: \(presentationError)")
            appState.setError(presentationError)
        }
    }

    func fetchFriendsCurrentlyPlaying() async {
        let result =
            await bluebirdAccountAPIService.getFriendsCurrentlyPlaying()
        switch result {
        case let .success(userIDTrackMap):
            friendsCurrentlyPlaying = userIDTrackMap.friends

        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error refreshing history: \(presentationError)")
            appState.setError(presentationError)
        }
    }

    func sendFriendRequest(to userId: String) async {
        let result = await bluebirdAccountAPIService.sendFriendRequest(
            to: userId
        )
        switch result {
        case .success:
            if var profile = currentUserProfile, profile.user_id == userId {
                profile.display_friendship_status = .outgoing
                currentUserProfile = profile
                userProfileDetailCache[userId] = (profile, Date())
            }
        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error sending friend request: \(presentationError)")
            appState.setError(presentationError)
        }
    }

    func removeFriend(friend userId: String) async {
        let result = await bluebirdAccountAPIService.removeFriend(
            friend: userId
        )
        switch result {
        case .success:
            // needs changing
            if var profile = currentUserProfile, profile.user_id == userId {
                profile.display_friendship_status = .none
                currentUserProfile = profile
                userProfileDetailCache[userId] = (profile, Date())
            }
        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error removing friend: \(presentationError)")
            appState.setError(presentationError)
        }
    }

    func respondToFriendRequests(to userId: String, accept: Bool) async {
        let result = await bluebirdAccountAPIService.respondToFriendRequest(
            to: userId,
            accept: accept
        )
        switch result {
        case .success:
            if var profile = currentUserProfile, profile.user_id == userId {
                profile.display_friendship_status = accept ? .friends : .none
                currentUserProfile = profile
                userProfileDetailCache[userId] = (profile, Date())
            }
        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error responding to friend request: \(presentationError)")
            appState.setError(presentationError)
        }
    }

    // MARK: - some cache helpers

    func invalidateCache(for userId: String) {
        userProfileDetailCache.removeValue(forKey: userId)
    }

    func clearCache() {
        userProfileDetailCache.removeAll()
    }

    // then want to show reposts.

    // TODO: -
    // Reposts:
    // Need to query the reposts of all friends.
    // then can return the details back for each repost,
    // alongside data such as:
    // timestamp, who reposted, caption?
    // make easy to extend via comments, not sure abvout this yet
    // Strategy: maybe fetch all reposts in the past x days? Limit by some amount of number?
    // But want to show all posts so maybe read all
    // then send back x, and allow pagination?
    // have feed function allowing pagination

    // need remove friend button
}
