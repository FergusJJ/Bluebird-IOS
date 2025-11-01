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

    @Relationship(inverse: \CachedUserAccount.profile) var account:
        CachedUserAccount?

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

    @Relationship(inverse: \CachedUserAccount.songHistory) var account:
        CachedUserAccount?

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

    // Time-based stats with expiry
    var hourlyPlaysData: Data?  // Encoded [HourlyPlay]
    var hourlyPlaysExpiry: Date?
    var hourlyPlaysDays: Int?

    var dailyPlaysData: Data?  // Encoded [DailyPlay]
    var dailyPlaysExpiry: Date?

    var topArtistsData: Data?  // Encoded TopArtists
    var topArtistsExpiry: Date?
    var topArtistsDays: Int?

    var topTracksData: Data?  // Encoded TopTracks
    var topTracksExpiry: Date?
    var topTracksDays: Int?

    var topGenresData: Data?  // Encoded GenreCounts
    var topGenresExpiry: Date?
    var topGenresDays: Int?

    var discoveriesData: Data?  // Encoded Discoveries
    var discoveriesExpiry: Date?

    var weeklyComparisonData: Data?  // Encoded WeeklyPlatformComparison
    var weeklyComparisonExpiry: Date?

    @Relationship(inverse: \CachedUserAccount.stats) var account:
        CachedUserAccount?

    init() {
        // Initialize with nil values
    }

    func setHourlyPlaysMinutes(_ plays: [HourlyPlay]) {
        hourlyPlaysData = try? JSONEncoder().encode(plays)
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

    // Helper methods for encoding/decoding
    func setHourlyPlays(
        _ plays: [HourlyPlay],
        days: Int,
        ttl: TimeInterval = 3600
    ) {
        hourlyPlaysData = try? JSONEncoder().encode(plays)
        hourlyPlaysDays = days
        hourlyPlaysExpiry = Date().addingTimeInterval(ttl)
    }

    func getHourlyPlays(for days: Int) -> [HourlyPlay]? {
        guard let data = hourlyPlaysData,
            let expiry = hourlyPlaysExpiry,
            let cachedDays = hourlyPlaysDays,
            cachedDays == days,
            Date() < expiry
        else { return nil }
        return try? JSONDecoder().decode([HourlyPlay].self, from: data)
    }

    func setTopArtists(
        _ artists: TopArtists,
        days: Int,
        ttl: TimeInterval = 3600
    ) {
        topArtistsData = try? JSONEncoder().encode(artists)
        topArtistsDays = days
        topArtistsExpiry = Date().addingTimeInterval(ttl)
    }

    func getTopArtists(for days: Int) -> TopArtists? {
        guard let data = topArtistsData,
            let expiry = topArtistsExpiry,
            let cachedDays = topArtistsDays,
            cachedDays == days,
            Date() < expiry
        else { return nil }
        return try? JSONDecoder().decode(TopArtists.self, from: data)
    }

    func setTopTracks(_ tracks: TopTracks, days: Int, ttl: TimeInterval = 3600)
    {
        topTracksData = try? JSONEncoder().encode(tracks)
        topTracksDays = days
        topTracksExpiry = Date().addingTimeInterval(ttl)
    }

    func getTopTracks(for days: Int) -> TopTracks? {
        guard let data = topTracksData,
            let expiry = topTracksExpiry,
            let cachedDays = topTracksDays,
            cachedDays == days,
            Date() < expiry
        else { return nil }
        return try? JSONDecoder().decode(TopTracks.self, from: data)
    }

    func setTopGenres(
        _ genres: GenreCounts,
        days: Int,
        ttl: TimeInterval = 3600
    ) {
        topGenresData = try? JSONEncoder().encode(genres)
        topGenresDays = days
        topGenresExpiry = Date().addingTimeInterval(ttl)
    }

    func getTopGenres(for days: Int) -> GenreCounts? {
        guard let data = topGenresData,
            let expiry = topGenresExpiry,
            let cachedDays = topGenresDays,
            cachedDays == days,
            Date() < expiry
        else { return nil }
        return try? JSONDecoder().decode(GenreCounts.self, from: data)
    }

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

    @Relationship(inverse: \CachedUserAccount.pins) var account:
        CachedUserAccount?

    init() {
        trackPins = Data()
        albumPins = Data()
        artistPins = Data()
        trackDetails = Data()
        albumDetails = Data()
        artistDetails = Data()
        lastUpdated = Date()
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
    var expiresAt: Date

    @Relationship(inverse: \CachedUserAccount.socialCache) var account:
        CachedUserAccount?

    init(viewerId: String, profile: UserProfileDetail, ttl: TimeInterval = 300)
    {
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
        guard Date() < expiresAt else { return nil }
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

    @Relationship(inverse: \CachedUserAccount.milestones) var account:
        CachedUserAccount?

    init() {
        milestones = Data()
        lastUpdated = Date()
    }

    func setMilestones(_ userMilestones: [UserMilestone]) {
        milestones = (try? JSONEncoder().encode(userMilestones)) ?? Data()
        lastUpdated = Date()
    }
    func getMilestones() -> [UserMilestone] {
        let milestoneCache =
            (try? JSONDecoder().decode([UserMilestone].self, from: milestones))
            ?? []
        return milestoneCache
    }
}
