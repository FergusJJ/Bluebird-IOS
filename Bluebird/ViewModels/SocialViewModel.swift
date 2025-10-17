import SwiftUI

@MainActor
class SocialViewModel: ObservableObject {
    @Published var currentUserProfile: UserProfileDetail?
    @Published var friendsCurrentlyPlaying: [String: FriendCurrentlyPlaying] =
        [:]
    @Published var userReposts: [RepostItem] = []
    @Published var isLoadingReposts = false
    @Published private(set) var repostsNextCursor: String = ""

    @Published var feedPosts: [FeedPostItem] = []
    @Published var isLoadingFeed = false
    @Published private(set) var feedHasMore = false
    @Published private(set) var feedNextOffset = 0

    private var appState: AppState
    private let cacheManager = CacheManager.shared
    private let bluebirdAccountAPIService: BluebirdAccountAPIService

    private var userProfileDetailCache:
        [String: (profile: UserProfileDetail, timestamp: Date)] = []

    init(
        appState: AppState,
        bluebirdAccountAPIService: BluebirdAccountAPIService
    ) {
        self.appState = appState
        self.bluebirdAccountAPIService = bluebirdAccountAPIService
    }

    func fetchUserProfile(userId: String, forceRefresh: Bool) async {
        if !forceRefresh {
            if let cached = cacheManager.getUserProfile(userId: userId) {
                currentUserProfile = cached
                return
            }
        }
        let result = await bluebirdAccountAPIService.getUser(userID: userId)
        switch result {
        case let .success(profileDetail):
            currentUserProfile = profileDetail
            cacheManager.saveUserProfile(profileDetail)

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

    func createRepost(
        on entityType: EntityType,
        for entityID: String,
        caption: String
    ) async -> PostCreatedResponse? {
        let result = await bluebirdAccountAPIService.createRepost(
            on: entityType,
            for: entityID,
            caption: caption
        )
        switch result {
        case let .success(createPostResponse):
            return createPostResponse
        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print(
                "Error creating post: \(serviceError.localizedDescription) \(presentationError.localizedDescription)"
            )
            return nil
        }
    }

    // MARK: - Cache Helpers

    func invalidateCache(for userId: String) {
        cacheManager.invalidateSocialCache(for: userId)
    }

    func clearCache() {
        cacheManager.invalidateSocialCache()
    }

    func fetchUserReposts(userId: String, forceRefresh: Bool = false) async {
        if !forceRefresh && !userReposts.isEmpty {
            return
        }

        isLoadingReposts = true
        let result = await bluebirdAccountAPIService.getUserReposts(
            userID: userId,
            cursor: nil,
            limit: 50
        )

        switch result {
        case let .success(response):
            userReposts = response.reposts
            repostsNextCursor = response.next_cursor

        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error fetching user reposts: \(presentationError)")
            appState.setError(presentationError)
        }
        isLoadingReposts = false
    }

    func loadMoreUserReposts(userId: String) async {
        guard !repostsNextCursor.isEmpty && !isLoadingReposts else { return }

        isLoadingReposts = true
        let result = await bluebirdAccountAPIService.getUserReposts(
            userID: userId,
            cursor: repostsNextCursor,
            limit: 50
        )

        switch result {
        case let .success(response):
            userReposts.append(contentsOf: response.reposts)
            repostsNextCursor = response.next_cursor

        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error loading more reposts: \(presentationError)")
            appState.setError(presentationError)
        }
        isLoadingReposts = false
    }

    // MARK: - Feed

    func fetchFeed(forceRefresh: Bool = false) async {
        if !forceRefresh && !feedPosts.isEmpty {
            return
        }

        isLoadingFeed = true
        let result = await bluebirdAccountAPIService.getFeed(
            limit: 20,
            offset: 0
        )

        switch result {
        case let .success(response):
            feedPosts = response.posts
            feedHasMore = response.has_more
            feedNextOffset = response.next_offset

        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error fetching feed: \(presentationError)")
            appState.setError(presentationError)
        }
        isLoadingFeed = false
    }

    func loadMoreFeedPosts() async {
        guard feedHasMore && !isLoadingFeed else { return }

        isLoadingFeed = true
        let result = await bluebirdAccountAPIService.getFeed(
            limit: 20,
            offset: feedNextOffset
        )

        switch result {
        case let .success(response):
            feedPosts.append(contentsOf: response.posts)
            feedHasMore = response.has_more
            feedNextOffset = response.next_offset

        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error loading more feed posts: \(presentationError)")
            appState.setError(presentationError)
        }
        isLoadingFeed = false
    }

    func deletePost(postID: String) async -> Bool {
        let result = await bluebirdAccountAPIService.deleteRepost(postID: postID)

        switch result {
        case .success():
            // Remove from feed
            feedPosts.removeAll { $0.post.post_id == postID }
            return true

        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error deleting post: \(presentationError)")
            appState.setError(presentationError)
            return false
        }
    }
}
