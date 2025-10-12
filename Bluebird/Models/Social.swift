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
