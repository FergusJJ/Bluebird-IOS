import SwiftUI

@MainActor
class SocialViewModel: ObservableObject, TryRequestViewModel, CachedViewModel {
    @Published var currentUserProfile: UserProfileDetail?
    @Published var friendsCurrentlyPlaying: [String: FriendCurrentlyPlaying] =
        [:]

    @Published var userRepostsCache: [String: [RepostItem]] = [:]
    @Published private(set) var repostsCursorCache: [String: String] = [:]
    @Published var isLoadingReposts = false

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

    internal var appState: AppState
    let cacheManager = CacheManager.shared
    private let bluebirdAccountAPIService: BluebirdAccountAPIService

    private var userProfileDetailCache: [String: (profile: UserProfileDetail, timestamp: Date)] =
        [:]

    init(
        appState: AppState,
        bluebirdAccountAPIService: BluebirdAccountAPIService
    ) {
        self.appState = appState
        self.bluebirdAccountAPIService = bluebirdAccountAPIService
    }

    func fetchUserProfile(userId: String, forceRefresh: Bool = false) async {
        await fetchWithCache(
            cacheGetter: { [weak self] in
                self?.cacheManager.getUserProfile(userId: userId)
            },
            apiFetch: { [weak self] in
                guard let self = self else { return nil }
                return await tryRequest(
                    { await self.bluebirdAccountAPIService.getUser(userID: userId) },
                    "Error fetching user profile"
                )
            },
            onUpdate: { [weak self] profile in
                self?.currentUserProfile = profile
            },
            cacheSetter: { [weak self] profile in
                self?.cacheManager.saveUserProfile(profile)
            },
            forceRefresh: forceRefresh
        )
    }

    func fetchUserMilestones(userId: String) async {
        if let milestones = await tryRequest(
            { await bluebirdAccountAPIService.getMilestones(userID: userId) },
            "Error fetching user milestones"
        ) {
            userMilestones = milestones
        }
    }

    func fetchUserFriends(userId: String) async {
        if let friends = await tryRequest(
            { await bluebirdAccountAPIService.getAllFriends(for: userId) },
            "Error fetching user friends"
        ) {
            userFriends = friends
        }
    }

    func fetchFriendsCurrentlyPlaying() async {
        if let userIDTrackMap = await tryRequest(
            { await bluebirdAccountAPIService.getFriendsCurrentlyPlaying() },
            "Error fetching friends currently playing"
        ) {
            friendsCurrentlyPlaying = userIDTrackMap.friends
        }
    }

    func fetchTrendingTracks(forceRefresh: Bool = false) async {
        // Prevent concurrent requests
        if !trendingTracks.isEmpty && !forceRefresh {
            return
        }
        guard !isLoadingTrending else { return }
        isLoadingTrending = true
        defer { isLoadingTrending = false }

        if let tracks = await tryRequest(
            { await bluebirdAccountAPIService.getTrendingTracks() },
            "Error fetching trending tracks"
        ) {
            trendingTracks = tracks
        }
    }

    func toggleShowAllTrending() {
        showAllTrending.toggle()
    }

    func sendFriendRequest(to userId: String) async {
        let result = await tryRequest(
            { await bluebirdAccountAPIService.sendFriendRequest(to: userId) },
            "Error sending friend request"
        )

        if result != nil {
            if var profile = currentUserProfile, profile.user_id == userId {
                profile.display_friendship_status = .outgoing
                currentUserProfile = profile
                userProfileDetailCache[userId] = (profile, Date())
            }
        }
    }

    func removeFriend(friend userId: String) async {
        let result = await tryRequest(
            { await bluebirdAccountAPIService.removeFriend(friend: userId) },
            "Error removing friend"
        )

        if result != nil {
            if var profile = currentUserProfile, profile.user_id == userId {
                profile.display_friendship_status = .none
                currentUserProfile = profile
                userProfileDetailCache[userId] = (profile, Date())
            }
            CacheManager.shared.expireFriendsCache()
        }
    }

    func respondToFriendRequests(to userId: String, accept: Bool) async {
        let result = await tryRequest(
            {
                await bluebirdAccountAPIService.respondToFriendRequest(
                    to: userId,
                    accept: accept
                )
            },
            "Error responding to friend request"
        )

        if result != nil {
            if var profile = currentUserProfile, profile.user_id == userId {
                profile.display_friendship_status = accept ? .friends : .none
                currentUserProfile = profile
                userProfileDetailCache[userId] = (profile, Date())
            }

            if accept {
                CacheManager.shared.expireFriendsCache()
            }
        }
    }

    func createRepost(
        on entityType: EntityType,
        for entityID: String,
        caption: String
    ) async -> PostCreatedResponse? {
        return await tryRequest(
            {
                await bluebirdAccountAPIService.createRepost(
                    on: entityType,
                    for: entityID,
                    caption: caption
                )
            },
            "Error creating post"
        )
    }

    func getReposts(for userId: String) -> [RepostItem] {
        return userRepostsCache[userId] ?? []
    }

    func getRepostsCursor(for userId: String) -> String {
        return repostsCursorCache[userId] ?? ""
    }

    func fetchUserReposts(userId: String, forceRefresh: Bool = false) async {
        //FIX: UPDATE TO USE CACHE
        // TODO: -
        if !forceRefresh && !getReposts(for: userId).isEmpty {
            return
        }

        isLoadingReposts = true

        if let response = await tryRequest(
            {
                await bluebirdAccountAPIService.getUserReposts(
                    userID: userId,
                    cursor: nil,
                    limit: 50
                )
            },
            "Error fetching user reposts"
        ) {
            userRepostsCache[userId] = response.reposts
            repostsCursorCache[userId] = response.next_cursor
        }
        isLoadingReposts = false
    }

    func loadMoreUserReposts(userId: String) async {
        guard !getRepostsCursor(for: userId).isEmpty && !isLoadingReposts else {
            return
        }

        isLoadingReposts = true

        if let response = await tryRequest(
            {
                await bluebirdAccountAPIService.getUserReposts(
                    userID: userId,
                    cursor: getRepostsCursor(for: userId),
                    limit: 50
                )
            },
            "Error fetching more user reposts"
        ) {
            userRepostsCache[userId]?.append(contentsOf: response.reposts)
            repostsCursorCache[userId] = response.next_cursor
        }
        isLoadingReposts = false
    }

    // MARK: - Feed

    func fetchFeed(forceRefresh: Bool = false) async {
        if !forceRefresh && !feedPosts.isEmpty {
            return
        }

        isLoadingFeed = true

        if let response = await tryRequest(
            { await bluebirdAccountAPIService.getFeed(limit: 20, offset: 0) },
            "Error fetching feed"
        ) {
            feedPosts = response.posts
            feedHasMore = response.has_more
            feedNextOffset = response.next_offset
        }
        isLoadingFeed = false
    }

    func loadMoreFeedPosts() async {
        guard feedHasMore && !isLoadingFeed else { return }

        isLoadingFeed = true

        if let response = await tryRequest(
            {
                await bluebirdAccountAPIService.getFeed(
                    limit: 20,
                    offset: feedNextOffset
                )
            },
            "Error fetching more feed posts"
        ) {
            feedPosts.append(contentsOf: response.posts)
            feedHasMore = response.has_more
            feedNextOffset = response.next_offset
        }
        isLoadingFeed = false
    }

    // MARK: - Unified Feed (with highlights)

    func fetchUnifiedFeed(forceRefresh: Bool = false) async {
        if !forceRefresh && !unifiedFeedItems.isEmpty {
            return
        }

        guard !isLoadingUnifiedFeed else {
            return
        }

        isLoadingUnifiedFeed = true
        defer { isLoadingUnifiedFeed = false }

        if let response = await tryRequest(
            {
                await bluebirdAccountAPIService.getUnifiedFeed(
                    limit: 20,
                    offset: 0,
                    includeHighlights: true
                )
            },
            "Error fetching unified feed"
        ) {
            unifiedFeedItems = response.items
            unifiedFeedHasMore = response.has_more
            unifiedFeedNextOffset = response.next_offset
        }
    }

    func loadMoreUnifiedFeedItems() async {
        guard unifiedFeedHasMore && !isLoadingUnifiedFeed else { return }

        isLoadingUnifiedFeed = true

        if let response = await tryRequest(
            {
                await bluebirdAccountAPIService.getUnifiedFeed(
                    limit: 20,
                    offset: unifiedFeedNextOffset,
                    includeHighlights: true
                )
            },
            "Error fetching more unified feed items"
        ) {
            unifiedFeedItems.append(contentsOf: response.items)
            unifiedFeedHasMore = response.has_more
            unifiedFeedNextOffset = response.next_offset
        }
        isLoadingUnifiedFeed = false
    }

    func deletePost(postID: String) async -> Bool {
        let result: Void? = await tryRequest(
            { await bluebirdAccountAPIService.deleteRepost(postID: postID) },
            "Error deleting post"
        )

        if result != nil {
            // Remove from regular feed
            feedPosts.removeAll { $0.post.post_id == postID }
            // Remove from unified feed
            unifiedFeedItems.removeAll { $0.post_id == postID }
            return true
        }
        return false
    }

    func clearReposts(for userId: String) {
        guard !getReposts(for: userId).isEmpty && !isLoadingReposts else {
            return
        }
        userRepostsCache.removeValue(forKey: userId)
        repostsCursorCache.removeValue(forKey: userId)
    }
}
