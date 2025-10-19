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

    // Unified feed (with highlights)
    @Published var unifiedFeedItems: [UnifiedFeedItem] = []
    @Published var isLoadingUnifiedFeed = false
    @Published private(set) var unifiedFeedHasMore = false
    @Published private(set) var unifiedFeedNextOffset = 0

    @Published var trendingTracks: [TrendingTrack] = []
    @Published var isLoadingTrending = false
    @Published var showAllTrending = false

    // Milestones for viewed user profile
    @Published var userMilestones: [UserMilestone] = []

    // Friends for viewed user profile
    @Published var userFriends: [UserProfile] = []

    private var appState: AppState
    private let cacheManager = CacheManager.shared
    private let bluebirdAccountAPIService: BluebirdAccountAPIService

    private var userProfileDetailCache:
    [String: (profile: UserProfileDetail, timestamp: Date)] = [:]

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

    func fetchUserMilestones(userId: String) async {
        let result = await bluebirdAccountAPIService.getMilestones(userID: userId)
        switch result {
        case let .success(milestones):
            userMilestones = milestones

        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error fetching user milestones: \(presentationError)")
            appState.setError(presentationError)
        }
    }

    func fetchUserFriends(userId: String) async {
        let result = await bluebirdAccountAPIService.getAllFriends(for: userId)
        switch result {
        case let .success(friends):
            userFriends = friends

        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error fetching user friends: \(presentationError)")
            appState.setError(presentationError)
        }
    }

    func fetchFriendsCurrentlyPlaying() async {
        print("DEBUG: fetchFriendsCurrentlyPlaying called")
        let result =
            await bluebirdAccountAPIService.getFriendsCurrentlyPlaying()
        switch result {
        case let .success(userIDTrackMap):
            print("DEBUG: Got currently playing data - count: \(userIDTrackMap.friends.count)")
            friendsCurrentlyPlaying = userIDTrackMap.friends
            print("DEBUG: Set friendsCurrentlyPlaying - count now: \(friendsCurrentlyPlaying.count)")

        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error refreshing history: \(presentationError)")
            appState.setError(presentationError)
        }
    }

    func fetchTrendingTracks() async {
        // Prevent concurrent requests
        print("fetchTrendingTracks - isLoadingTrending=\(isLoadingTrending)")
        guard !isLoadingTrending else { return }
        print("fetchTrendingTracks - passed guard isLoadingTrending=\(isLoadingTrending)")

        isLoadingTrending = true
        defer {isLoadingTrending = false}
        print("fetchTrendingTracks - getting result")
        let result = await bluebirdAccountAPIService.getTrendingTracks()
        print("fetchTrendingTracks - got result")
        switch result {
        case let .success(tracks):
            trendingTracks = tracks

        case let .failure(serviceError):
            // Silently ignore cancellation errors (code -999) - these happen when refresh controls overlap
            if case .networkError(let error as NSError) = serviceError,
               error.domain == NSURLErrorDomain,
               error.code == NSURLErrorCancelled {
                print("Trending fetch cancelled by iOS (refresh control conflict, this is normal)")
                return
            }

            let presentationError = AppError(from: serviceError)
            print("Error fetching trending tracks: \(presentationError)")
            appState.setError(presentationError)
        }
    }

    func toggleShowAllTrending() {
        showAllTrending.toggle()
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

    // MARK: - Unified Feed (with highlights)

    func fetchUnifiedFeed(forceRefresh: Bool = false) async {
        if !forceRefresh && !unifiedFeedItems.isEmpty {
            return
        }

        isLoadingUnifiedFeed = true
        let result = await bluebirdAccountAPIService.getUnifiedFeed(
            limit: 20,
            offset: 0,
            includeHighlights: true
        )

        switch result {
        case let .success(response):
            unifiedFeedItems = response.items
            unifiedFeedHasMore = response.has_more
            unifiedFeedNextOffset = response.next_offset

        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error fetching unified feed: \(presentationError)")
            appState.setError(presentationError)
        }
        isLoadingUnifiedFeed = false
    }

    func loadMoreUnifiedFeedItems() async {
        guard unifiedFeedHasMore && !isLoadingUnifiedFeed else { return }

        isLoadingUnifiedFeed = true
        let result = await bluebirdAccountAPIService.getUnifiedFeed(
            limit: 20,
            offset: unifiedFeedNextOffset,
            includeHighlights: true
        )

        switch result {
        case let .success(response):
            unifiedFeedItems.append(contentsOf: response.items)
            unifiedFeedHasMore = response.has_more
            unifiedFeedNextOffset = response.next_offset

        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error loading more unified feed items: \(presentationError)")
            appState.setError(presentationError)
        }
        isLoadingUnifiedFeed = false
    }

    func deletePost(postID: String) async -> Bool {
        let result = await bluebirdAccountAPIService.deleteRepost(postID: postID)

        switch result {
        case .success():
            // Remove from regular feed
            feedPosts.removeAll { $0.post.post_id == postID }
            // Remove from unified feed
            unifiedFeedItems.removeAll { $0.post_id == postID }
            return true

        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error deleting post: \(presentationError)")
            appState.setError(presentationError)
            return false
        }
    }
}
