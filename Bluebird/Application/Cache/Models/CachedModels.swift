import Foundation
import SwiftData

// MARK: - User Account
// TODO - add repost cache
@Model
final class CachedUserAccount {
    @Attribute(.unique) var userId: String
    var username: String
    var email: String
    var lastSyncDate: Date

    // Relationships
    @Relationship(deleteRule: .cascade) var profile: CachedProfile?
    @Relationship(deleteRule: .cascade) var songHistory: [CachedSongHistory] =
        []
    @Relationship(deleteRule: .cascade) var stats: CachedStats?
    @Relationship(deleteRule: .cascade) var pins: CachedPins?
    @Relationship(deleteRule: .cascade) var milestones: CachedMilestone?
    @Relationship(deleteRule: .cascade) var socialCache: [CachedUserProfile] =
        []
    @Relationship(deleteRule: .cascade) var friendsList: CachedFriendsList?

    init(userId: String, username: String, email: String) {
        self.userId = userId
        self.username = username
        self.email = email
        lastSyncDate = Date()
    }
}

// MARK: - Profile

@Model
final class CachedProfile {
    var username: String
    var bio: String
    var avatarUrl: String
    var profileVisibility: String?
    var totalMinutesListened: Int
    var totalPlays: Int
    var totalUniqueArtists: Int
    var lastUpdated: Date
    var expiresAt: Date?

    @Relationship(inverse: \CachedUserAccount.profile) var account: CachedUserAccount?

    init(
        username: String,
        bio: String,
        avatarUrl: String,
        profileVisibility: String
    ) {
        self.username = username
        self.bio = bio
        self.avatarUrl = avatarUrl
        self.profileVisibility = profileVisibility
        totalMinutesListened = 0
        totalPlays = 0
        totalUniqueArtists = 0
        lastUpdated = Date()
        expiresAt = Date().addingTimeInterval(CacheTTL.profile)  // New entries get expiry
    }
}

// MARK: - Song History

@Model
final class CachedSongHistory {
    @Attribute(.unique) var compositeId: String  // userId_timestamp
    var timestamp: Int
    var trackId: String
    var albumId: String
    var name: String
    var artistsData: Data  // Encoded [SongDetailArtist]
    var durationMs: Int
    var spotifyUrl: String
    var albumName: String
    var albumImageUrl: String
    var lastUpdated: Date?  // Optional to allow migration of existing data

    @Relationship(inverse: \CachedUserAccount.songHistory) var account: CachedUserAccount?

    init(userId: String, song: SongDetail) {
        compositeId = "\(userId)_\(song.listened_at ?? 0)"
        timestamp = song.listened_at ?? 0
        trackId = song.track_id
        albumId = song.album_id
        name = song.name
        artistsData = (try? JSONEncoder().encode(song.artists)) ?? Data()
        durationMs = song.duration_ms
        spotifyUrl = song.spotify_url
        albumName = song.album_name
        albumImageUrl = song.album_image_url
        lastUpdated = Date()
    }

    func toSongDetail() -> SongDetail {
        let artists =
            (try? JSONDecoder().decode(
                [SongDetailArtist].self,
                from: artistsData
            )) ?? []
        return SongDetail(
            track_id: trackId,
            album_id: albumId,
            name: name,
            artists: artists,
            duration_ms: durationMs,
            spotify_url: spotifyUrl,
            album_name: albumName,
            album_image_url: albumImageUrl,
            listened_at: timestamp
        )
    }
}

// MARK: - Stats

@Model
final class CachedStats {

    var hourlyPlaysMinutesData: Data?
    var hourlyPlaysMinutesHour: Int?

    // Non-days-based stats (single value) - these are fine in SwiftData
    var dailyPlaysData: Data?
    var dailyPlaysExpiry: Date?

    var discoveriesData: Data?
    var discoveriesExpiry: Date?

    var weeklyComparisonData: Data?
    var weeklyComparisonExpiry: Date?

    @Relationship(inverse: \CachedUserAccount.stats) var account: CachedUserAccount?

    init() {
        // Initialize with nil values
    }

    func setHourlyPlaysMinutes(_ plays: [HourlyPlay]) {
        hourlyPlaysMinutesData = try? JSONEncoder().encode(plays)
        hourlyPlaysMinutesHour = Calendar.current.component(.hour, from: Date())
    }

    func getHourlyPlaysMinutes() -> [HourlyPlay]? {
        let currentHour = Calendar.current.component(.hour, from: Date())
        guard let data = hourlyPlaysMinutesData,
            let cachedHour = hourlyPlaysMinutesHour,
            cachedHour == currentHour
        else {
            hourlyPlaysMinutesData = nil
            hourlyPlaysMinutesHour = nil
            return nil
        }
        return try? JSONDecoder().decode([HourlyPlay].self, from: data)
    }

    // Days-based stats removed - use in-memory caching in ViewModels instead

    func setDiscoveries(_ discoveries: Discoveries, ttl: TimeInterval = 3600) {
        discoveriesData = try? JSONEncoder().encode(discoveries)
        discoveriesExpiry = Date().addingTimeInterval(ttl)
    }

    func getDiscoveries() -> Discoveries? {
        guard let data = discoveriesData,
            let expiry = discoveriesExpiry,
            Date() < expiry
        else { return nil }
        return try? JSONDecoder().decode(Discoveries.self, from: data)
    }

    func setDailyPlays(_ plays: [DailyPlay], ttl: TimeInterval = 3600) {
        dailyPlaysData = try? JSONEncoder().encode(plays)
        dailyPlaysExpiry = Date().addingTimeInterval(ttl)
    }

    func getDailyPlays() -> [DailyPlay]? {
        guard let data = dailyPlaysData,
            let expiry = dailyPlaysExpiry,
            Date() < expiry
        else { return nil }
        return try? JSONDecoder().decode([DailyPlay].self, from: data)
    }

    func setWeeklyComparison(
        _ comparison: WeeklyPlatformComparison,
        ttl: TimeInterval = 3600
    ) {
        weeklyComparisonData = try? JSONEncoder().encode(comparison)
        weeklyComparisonExpiry = Date().addingTimeInterval(ttl)
    }

    func getWeeklyComparison() -> WeeklyPlatformComparison? {
        guard let data = weeklyComparisonData,
            let expiry = weeklyComparisonExpiry,
            Date() < expiry
        else { return nil }
        return try? JSONDecoder().decode(
            WeeklyPlatformComparison.self,
            from: data
        )
    }
}

// MARK: - Pins

@Model
final class CachedPins {
    var trackPins: Data  // Encoded [Pin]
    var albumPins: Data  // Encoded [Pin]
    var artistPins: Data  // Encoded [Pin]

    var trackDetails: Data  // Encoded [String: SongDetail]
    var albumDetails: Data  // Encoded [String: AlbumDetail]
    var artistDetails: Data  // Encoded [String: ArtistDetail]

    var lastUpdated: Date
    var expiresAt: Date?  // Optional: No automatic expiry for manual sync

    @Relationship(inverse: \CachedUserAccount.pins) var account: CachedUserAccount?

    init() {
        trackPins = Data()
        albumPins = Data()
        artistPins = Data()
        trackDetails = Data()
        albumDetails = Data()
        artistDetails = Data()
        lastUpdated = Date()
        expiresAt = nil  // No automatic expiry
    }

    func setPins(
        _ pins: [Pin],
        tracks: [String: SongDetail],
        albums: [String: AlbumDetail],
        artists: [String: ArtistDetail]
    ) {
        let trackPinsArray = pins.filter { $0.entity_type == .track }
        let albumPinsArray = pins.filter { $0.entity_type == .album }
        let artistPinsArray = pins.filter { $0.entity_type == .artist }

        trackPins = (try? JSONEncoder().encode(trackPinsArray)) ?? Data()
        albumPins = (try? JSONEncoder().encode(albumPinsArray)) ?? Data()
        artistPins = (try? JSONEncoder().encode(artistPinsArray)) ?? Data()

        trackDetails = (try? JSONEncoder().encode(tracks)) ?? Data()
        albumDetails = (try? JSONEncoder().encode(albums)) ?? Data()
        artistDetails = (try? JSONEncoder().encode(artists)) ?? Data()

        lastUpdated = Date()
    }

    func getPins() -> (
        pins: [Pin], tracks: [String: SongDetail],
        albums: [String: AlbumDetail], artists: [String: ArtistDetail]
    ) {
        let tracks =
            (try? JSONDecoder().decode(
                [String: SongDetail].self,
                from: trackDetails
            )) ?? [:]
        let albums =
            (try? JSONDecoder().decode(
                [String: AlbumDetail].self,
                from: albumDetails
            )) ?? [:]
        let artists =
            (try? JSONDecoder().decode(
                [String: ArtistDetail].self,
                from: artistDetails
            )) ?? [:]

        let trackPinsArray =
            (try? JSONDecoder().decode([Pin].self, from: trackPins)) ?? []
        let albumPinsArray =
            (try? JSONDecoder().decode([Pin].self, from: albumPins)) ?? []
        let artistPinsArray =
            (try? JSONDecoder().decode([Pin].self, from: artistPins)) ?? []

        let allPins = trackPinsArray + albumPinsArray + artistPinsArray

        return (allPins, tracks, albums, artists)
    }
}

// MARK: - Social Cache

@Model
final class CachedUserProfile {
    @Attribute(.unique) var profileId: String  // userId_viewerId composite key
    var userId: String
    var username: String
    var avatarUrl: String
    var bio: String
    var profileData: Data  // Encoded UserProfileDetail
    var cachedAt: Date
    var expiresAt: Date?  // Optional for migration compatibility

    @Relationship(inverse: \CachedUserAccount.socialCache) var account: CachedUserAccount?

    init(viewerId: String, profile: UserProfileDetail, ttl: TimeInterval = 300) {
        profileId = "\(viewerId)_\(profile.user_id)"
        userId = profile.user_id
        username = profile.username
        avatarUrl = profile.avatar_url
        bio = profile.bio
        profileData = (try? JSONEncoder().encode(profile)) ?? Data()
        cachedAt = Date()
        expiresAt = Date().addingTimeInterval(ttl)
    }

    func toUserProfileDetail() -> UserProfileDetail? {
        guard let expiresAt = expiresAt, Date() < expiresAt else { return nil }
        return try? JSONDecoder().decode(
            UserProfileDetail.self,
            from: profileData
        )
    }
}

@Model
final class CachedMilestone {
    var milestones: Data
    var lastUpdated: Date
    var expiresAt: Date?  // Optional for migration compatibility

    @Relationship(inverse: \CachedUserAccount.milestones) var account: CachedUserAccount?

    init() {
        milestones = Data()
        lastUpdated = Date()
        expiresAt = Date().addingTimeInterval(CacheTTL.milestones)
    }

    func setMilestones(_ userMilestones: [UserMilestone]) {
        milestones = (try? JSONEncoder().encode(userMilestones)) ?? Data()
        lastUpdated = Date()
        expiresAt = Date().addingTimeInterval(CacheTTL.milestones)
    }

    func getMilestones() -> [UserMilestone]? {
        // If expiresAt is nil (legacy data), treat as expired
        guard let expiresAt = expiresAt, Date() < expiresAt else { return nil }
        return try? JSONDecoder().decode([UserMilestone].self, from: milestones)
    }
}

// MARK: - Friends List

@Model
final class CachedFriendsList {
    var friendsData: Data  // Encoded [UserProfile]
    var friendCount: Int
    var lastUpdated: Date
    var expiresAt: Date?  // Optional for consistency (though new model, no legacy data)

    @Relationship(inverse: \CachedUserAccount.friendsList) var account: CachedUserAccount?

    init(friends: [UserProfile]) {
        self.friendsData = (try? JSONEncoder().encode(friends)) ?? Data()
        self.friendCount = friends.count
        self.lastUpdated = Date()
        self.expiresAt = Date().addingTimeInterval(CacheTTL.friends)
    }

    func getFriends() -> [UserProfile]? {
        // If expiresAt is nil, treat as expired
        guard let expiresAt = expiresAt, Date() < expiresAt else { return nil }
        return try? JSONDecoder().decode([UserProfile].self, from: friendsData)
    }

    func updateFriends(_ friends: [UserProfile]) {
        self.friendsData = (try? JSONEncoder().encode(friends)) ?? Data()
        self.friendCount = friends.count
        self.lastUpdated = Date()
        self.expiresAt = Date().addingTimeInterval(CacheTTL.friends)
    }
}
