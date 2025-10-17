import Foundation
import SwiftData
import SwiftUI

@MainActor
class CacheManager: ObservableObject {
    static let shared = CacheManager()

    private var container: ModelContainer
    private var context: ModelContext?
    private var currentUserId: String?

    lazy var modelContainer: ModelContainer = container

    private init() {
        do {
            let schema = Schema([
                CachedUserAccount.self,
                CachedProfile.self,
                CachedSongHistory.self,
                CachedStats.self,
                CachedPins.self,
                CachedUserProfile.self,
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )

            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            context = container.mainContext
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    private func setupContainer() {
        do {
            let schema = Schema([
                CachedUserAccount.self,
                CachedProfile.self,
                CachedSongHistory.self,
                CachedStats.self,
                CachedPins.self,
                CachedUserProfile.self,
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )

            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            context = container.mainContext
        } catch {
            print("Failed to create ModelContainer: \(error)")
        }
    }

    // MARK: - Account Management

    func getCurrentUserId() -> String? {
        return currentUserId
    }

    func setCurrentUser(userId: String, username: String, email: String) {
        currentUserId = userId

        // Ensure account exists
        guard let context = context else { return }

        let descriptor = FetchDescriptor<CachedUserAccount>(
            predicate: #Predicate { $0.userId == userId }
        )

        do {
            let accounts = try context.fetch(descriptor)
            if accounts.isEmpty {
                let newAccount = CachedUserAccount(
                    userId: userId,
                    username: username,
                    email: email
                )
                context.insert(newAccount)
                try context.save()
            }
        } catch {
            print("Error setting current user: \(error)")
        }
    }

    func clearCurrentUserData() {
        guard let userId = currentUserId, let context = context else { return }

        let descriptor = FetchDescriptor<CachedUserAccount>(
            predicate: #Predicate { $0.userId == userId }
        )

        do {
            let accounts = try context.fetch(descriptor)
            for account in accounts {
                context.delete(account) // Cascade delete will remove all related data
            }
            try context.save()
        } catch {
            print("Error clearing user data: \(error)")
        }

        currentUserId = nil
    }

    func clearAllData() {
        guard let context = context else { return }

        do {
            // Delete all accounts (cascade will handle related data)
            let accounts = try context.fetch(
                FetchDescriptor<CachedUserAccount>()
            )
            for account in accounts {
                context.delete(account)
            }
            try context.save()
        } catch {
            print("Error clearing all data: \(error)")
        }

        currentUserId = nil
    }

    private func getCurrentAccount() -> CachedUserAccount? {
        guard let userId = currentUserId, let context = context else {
            return nil
        }

        let userIdValue = userId
        let descriptor = FetchDescriptor<CachedUserAccount>(
            predicate: #Predicate { $0.userId == userIdValue }
        )

        return try? context.fetch(descriptor).first
    }

    // MARK: - Profile Cache

    func saveProfile(_ profile: ProfileInfo, stats: HeadlineViewStats?) {
        guard let account = getCurrentAccount(), let context = context else {
            return
        }

        if account.profile == nil {
            let cached = CachedProfile(
                username: profile.username,
                bio: profile.bio,
                avatarUrl: profile.avatarUrl
            )
            account.profile = cached
            context.insert(cached)
        } else {
            account.profile?.username = profile.username
            account.profile?.bio = profile.bio
            account.profile?.avatarUrl = profile.avatarUrl
            account.profile?.lastUpdated = Date()
        }

        if let stats = stats {
            account.profile?.totalPlays = stats.total_plays
            account.profile?.totalMinutesListened =
                stats.total_duration_millis / (60 * 1000)
            account.profile?.totalUniqueArtists = stats.unique_artists
        }

        try? context.save()
    }

    func getProfile() -> (profile: ProfileInfo?, stats: HeadlineViewStats?) {
        guard let cached = getCurrentAccount()?.profile else {
            return (nil, nil)
        }

        let profile = ProfileInfo(
            message: "",
            username: cached.username,
            bio: cached.bio,
            avatarUrl: cached.avatarUrl
        )

        let stats = HeadlineViewStats(
            total_plays: cached.totalPlays,
            unique_artists: cached.totalUniqueArtists,
            total_duration_millis: cached.totalMinutesListened * 60 * 1000
        )

        return (profile, stats)
    }

    // MARK: - Song History Cache

    func saveSongHistory(_ songs: [Int: SongDetail]) {
        guard let account = getCurrentAccount(),
              let context = context,
              let userId = currentUserId
        else { return }

        for (_, song) in songs {
            let cached = CachedSongHistory(userId: userId, song: song)

            // Check if already exists
            let compositeId = cached.compositeId
            let descriptor = FetchDescriptor<CachedSongHistory>(
                predicate: #Predicate { $0.compositeId == compositeId }
            )

            if let existing = try? context.fetch(descriptor).first {
                // Update existing
                existing.name = song.name
                existing.albumName = song.album_name
                existing.albumImageUrl = song.album_image_url
            } else {
                // Insert new
                context.insert(cached)
                account.songHistory.append(cached)
            }
        }

        try? context.save()
    }

    func getSongHistory() -> [Int: SongDetail] {
        guard let account = getCurrentAccount() else { return [:] }

        var history: [Int: SongDetail] = [:]
        for cached in account.songHistory {
            let song = cached.toSongDetail()
            if let timestamp = song.listened_at {
                history[timestamp] = song
            }
        }
        return history
    }

    func getSongHistoryLastUpdated() -> Date? {
        guard let account = getCurrentAccount() else { return nil }

        // Get the most recent lastUpdated timestamp from all cached songs
        // Filter out nil values for backward compatibility with migrated data
        return account.songHistory.compactMap { $0.lastUpdated }.max()
    }

    // MARK: - Stats Cache

    func saveHourlyPlays(_ plays: [HourlyPlay], days: Int) {
        guard let account = getCurrentAccount(), let context = context else {
            return
        }

        if account.stats == nil {
            let stats = CachedStats()
            account.stats = stats
            context.insert(stats)
        }

        account.stats?.setHourlyPlays(plays, days: days, ttl: 3600) // 1 hour TTL
        try? context.save()
    }

    func getHourlyPlays(for days: Int) -> [HourlyPlay]? {
        return getCurrentAccount()?.stats?.getHourlyPlays(for: days)
    }

    func saveTopArtists(_ artists: TopArtists, days: Int) {
        guard let account = getCurrentAccount(), let context = context else {
            return
        }

        if account.stats == nil {
            let stats = CachedStats()
            account.stats = stats
            context.insert(stats)
        }

        account.stats?.setTopArtists(artists, days: days, ttl: 3600)
        try? context.save()
    }

    func getTopArtists(for days: Int) -> TopArtists? {
        return getCurrentAccount()?.stats?.getTopArtists(for: days)
    }

    func saveTopTracks(_ tracks: TopTracks, days: Int) {
        guard let account = getCurrentAccount(), let context = context else {
            return
        }

        if account.stats == nil {
            let stats = CachedStats()
            account.stats = stats
            context.insert(stats)
        }

        account.stats?.setTopTracks(tracks, days: days, ttl: 3600)
        try? context.save()
    }

    func getTopTracks(for days: Int) -> TopTracks? {
        return getCurrentAccount()?.stats?.getTopTracks(for: days)
    }

    func saveTopGenres(_ genres: GenreCounts, days: Int) {
        guard let account = getCurrentAccount(), let context = context else {
            return
        }

        if account.stats == nil {
            let stats = CachedStats()
            account.stats = stats
            context.insert(stats)
        }

        account.stats?.setTopGenres(genres, days: days, ttl: 3600)
        try? context.save()
    }

    func getTopGenres(for days: Int) -> GenreCounts? {
        return getCurrentAccount()?.stats?.getTopGenres(for: days)
    }

    func saveDiscoveries(_ discoveries: Discoveries) {
        guard let account = getCurrentAccount(), let context = context else {
            return
        }

        if account.stats == nil {
            let stats = CachedStats()
            account.stats = stats
            context.insert(stats)
        }

        account.stats?.setDiscoveries(discoveries, ttl: 3600)
        try? context.save()
    }

    func getDiscoveries() -> Discoveries? {
        return getCurrentAccount()?.stats?.getDiscoveries()
    }

    func saveDailyPlays(_ plays: [DailyPlay]) {
        guard let account = getCurrentAccount(), let context = context else {
            return
        }

        if account.stats == nil {
            let stats = CachedStats()
            account.stats = stats
            context.insert(stats)
        }

        account.stats?.setDailyPlays(plays, ttl: 3600)
        try? context.save()
    }

    func getDailyPlays() -> [DailyPlay]? {
        return getCurrentAccount()?.stats?.getDailyPlays()
    }

    func saveWeeklyComparison(_ comparison: WeeklyPlatformComparison) {
        guard let account = getCurrentAccount(), let context = context else {
            return
        }

        if account.stats == nil {
            let stats = CachedStats()
            account.stats = stats
            context.insert(stats)
        }

        account.stats?.setWeeklyComparison(comparison, ttl: 3600)
        try? context.save()
    }

    func getWeeklyComparison() -> WeeklyPlatformComparison? {
        return getCurrentAccount()?.stats?.getWeeklyComparison()
    }

    // MARK: - Pins Cache

    func savePins(
        _ pins: [Pin],
        tracks: [String: SongDetail],
        albums: [String: AlbumDetail],
        artists: [String: ArtistDetail]
    ) {
        guard let account = getCurrentAccount(), let context = context else {
            return
        }

        if account.pins == nil {
            let cachedPins = CachedPins()
            account.pins = cachedPins
            context.insert(cachedPins)
        }

        account.pins?.setPins(
            pins,
            tracks: tracks,
            albums: albums,
            artists: artists
        )
        try? context.save()
    }

    func getPins() -> (
        pins: [Pin], tracks: [String: SongDetail],
        albums: [String: AlbumDetail], artists: [String: ArtistDetail]
    )? {
        guard let pins = getCurrentAccount()?.pins else { return nil }
        return pins.getPins()
    }

    // MARK: - Social Cache

    func saveUserProfile(_ profile: UserProfileDetail) {
        guard let account = getCurrentAccount(),
              let context = context,
              let viewerId = currentUserId
        else { return }

        let profileId = "\(viewerId)_\(profile.user_id)"

        // Check if exists
        let descriptor = FetchDescriptor<CachedUserProfile>(
            predicate: #Predicate { $0.profileId == profileId }
        )

        do {
            if let existing = try context.fetch(descriptor).first {
                // Update existing
                existing.username = profile.username
                existing.avatarUrl = profile.avatar_url
                existing.bio = profile.bio
                existing.profileData =
                    (try? JSONEncoder().encode(profile)) ?? Data()
                existing.cachedAt = Date()
                existing.expiresAt = Date().addingTimeInterval(300) // 5 min TTL
            } else {
                // Create new
                let cached = CachedUserProfile(
                    viewerId: viewerId,
                    profile: profile,
                    ttl: 300
                )
                context.insert(cached)
                account.socialCache.append(cached)
            }
            try context.save()
        } catch {
            print("Error saving user profile: \(error)")
        }
    }

    func getUserProfile(userId: String) -> UserProfileDetail? {
        guard let viewerId = currentUserId else { return nil }

        let profileId = "\(viewerId)_\(userId)"
        let descriptor = FetchDescriptor<CachedUserProfile>(
            predicate: #Predicate { $0.profileId == profileId }
        )

        guard let cached = try? context?.fetch(descriptor).first,
              Date() < cached.expiresAt
        else { return nil }

        return cached.toUserProfileDetail()
    }

    // MARK: - Cache Invalidation

    func invalidateStatsCache() {
        guard let stats = getCurrentAccount()?.stats else { return }

        stats.hourlyPlaysExpiry = Date()
        stats.dailyPlaysExpiry = Date()
        stats.topArtistsExpiry = Date()
        stats.topTracksExpiry = Date()
        stats.topGenresExpiry = Date()
        stats.discoveriesExpiry = Date()

        try? context?.save()
    }

    func invalidateSocialCache(for userId: String? = nil) {
        guard let account = getCurrentAccount() else { return }

        if let userId = userId {
            // Invalidate specific user
            for cached in account.socialCache where cached.userId == userId {
                cached.expiresAt = Date()
            }
        } else {
            // Invalidate all
            for cached in account.socialCache {
                cached.expiresAt = Date()
            }
        }

        try? context?.save()
    }
}
