import Foundation

struct CurrentlyPlayingResponse: Decodable {
    let friends: [String: FriendCurrentlyPlaying]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        friends = try container.decode([String: FriendCurrentlyPlaying].self)
    }

    // Get all user IDs that have tracks
    var userIds: [String] {
        return Array(friends.keys)
    }
}

struct FriendCurrentlyPlaying: Decodable {
    let profile: UserProfile
    let track: SongDetail
}

struct SearchUserResult: Decodable {
    let users: [UserProfile]
    let total: Int
    let query: String
}

struct UserProfile: Encodable, Decodable, Identifiable, Hashable {
    let user_id: String
    let username: String
    let avatar_url: String
    let bio: String
    let connection_priority: Int

    var id: String { user_id }
}

struct SendFriendRequestBody: Encodable {
    let recipient_id: String
}

struct RespondFriendRequestBody: Encodable {
    let requester_id: String
    let accept: Bool
}

struct FriendRequestResponse: Decodable {
    let message: String
}

struct UserProfileDetail: Codable {
    let user_id: String
    let username: String
    let avatar_url: String
    let bio: String
    let is_private: Bool
    let friend_count: Int
    let pinned_tracks: [SongDetail]
    let pinned_albums: [AlbumDetail]
    let pinned_artists: [ArtistDetail]
    let total_minutes_listened: Int?
    let total_plays: Int?
    let total_unique_artists: Int?

    var friendship_status: FriendshipStatus

    var display_friendship_status: FriendshipStatus {
        get { friendship_status }
        set { friendship_status = newValue }
    }
}

enum FriendshipStatus: String, Codable {
    case friends
    case outgoing
    case incoming
    case none
}

struct PostActionBody: Codable {
    let action: String
    let post_id: String?
    let post_type: String?
    let entity_type: String?  // needed for repost only
    let entity_id: String?  // repost
    let caption: String
}

struct PostCreatedResponse: Codable {
    let message: String
    let post_id: String
    let created_at: Date
}

// MARK: - Leaderboard

struct LeaderboardEntry: Codable {
    let profile: UserProfile
    let play_count: Int
}

struct LeaderboardResponse: Codable {
    let current_user: LeaderboardEntry
    let leaderboard: [LeaderboardEntry]
}

enum LeaderboardType: String {
    case artist
    case track
}

enum LeaderboardScope: String {
    case global
    case friends
}

// MARK: - Reposts

struct Repost: Codable, Identifiable {
    let post_id: String
    let profile: UserProfile
    let entity_type: String  // "track", "album", or "artist"
    let entity_id: String
    let caption: String
    let created_at: Date
    let likes_count: Int
    let comments_count: Int
    let user_has_liked: Bool

    var id: String { post_id }
}

struct RepostItem: Codable, Identifiable {
    let repost: Repost
    let track_detail: SongDetail?
    let album_detail: AlbumDetail?
    let artist_detail: ArtistDetail?

    var id: String { repost.post_id }
}

struct RepostsResponse: Codable {
    let reposts: [RepostItem]
    let next_cursor: String
}

// MARK: - Feed

struct FeedPost: Codable, Identifiable {
    let post_id: String
    let author: UserProfile
    let post_type: String  // "repost"
    let entity_type: String  // "track", "album", or "artist"
    let entity_id: String
    let caption: String
    let created_at: Date
    let likes_count: Int
    let comments_count: Int
    let user_has_liked: Bool

    var id: String { post_id }
}

struct FeedPostItem: Codable, Identifiable {
    let post: FeedPost
    let track_detail: SongDetail?
    let album_detail: AlbumDetail?
    let artist_detail: ArtistDetail?

    var id: String { post.post_id }
}

struct FeedResponse: Codable {
    let posts: [FeedPostItem]
    let has_more: Bool
    let next_offset: Int
}

// MARK: - Unified Feed (with Highlights)

enum FeedContentType: String, Codable {
    case repost
    case highlightLoving = "highlight_loving"
    case highlightDiscovery = "highlight_discovery"
}

struct UnifiedFeedItem: Codable, Identifiable {
    let content_type: FeedContentType
    let timestamp: Date
    let post_id: String?
    let caption: String?
    let likes_count: Int?
    let comments_count: Int?
    let user_has_liked: Bool?
    let author: UserProfile
    let entity_type: String  // "track", "album", or "artist"
    let entity_id: String
    let track_detail: SongDetail?
    let album_detail: AlbumDetail?
    let artist_detail: ArtistDetail?
    let play_count: Int?
    let is_new_discovery: Bool?

    var id: String {
        if let postID = post_id {
            return postID
        }
        // needed for generated posts that arent explicitlty stored
        let timestampString = String(timestamp.timeIntervalSince1970)
        return "\(content_type.rawValue)_\(author.user_id)_\(entity_id)_\(timestampString)"
    }
}

struct UnifiedFeedResponse: Codable {
    let items: [UnifiedFeedItem]
    let has_more: Bool
    let next_offset: Int
}

// MARK: - Trending

struct TrendingTrack: Codable, Identifiable {
    let track: SongDetail
    let play_count: Int

    var id: String { track.track_id }
}
