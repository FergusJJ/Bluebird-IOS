import SwiftUI

@MainActor
class StatsViewModel: ObservableObject {
    private var appState: AppState

    @Published var hourlyPlaysMinutes: [Int] = Array(repeating: 0, count: 24)
    @Published var hourlyPlays: [Int] = Array(repeating: 0, count: 24)
    @Published var dailyPlays: [DailyPlay] = []
    @Published var topTracks: TopTracks = .init(tracks: [:])
    @Published var topArtists: TopArtists = .init(artists: [:])
    @Published var topGenres: GenreCounts = .init()

    @Published var discoveredArtists: [ArtistWithPlayCount] = []
    @Published var discoveredTracks: [TrackWithPlayCount] = []

    @Published var trackTrendCache: [String: [DailyPlayCount]] = [:]

    @Published var weeklyComparison: WeeklyPlatformComparison = .init()
    @Published var lastWeekTotalPlays: Int = 0
    @Published var thisWeekTotalPlays: Int = 0

    // In-memory session caches (keyed by days where applicable)
    private var hourlyPlaysMinutesCache: [Int]?
    private var hourlyPlaysMinutesCacheHour: Int?
    private var hourlyPlaysCache: [Int: [Int]] = [:]
    private var topTracksCache: [Int: TopTracks] = [:]
    private var topArtistsCache: [Int: TopArtists] = [:]
    private var topGenresCache: [Int: GenreCounts] = [:]
    private var dailyPlaysCache: [DailyPlay]?
    private var discoveriesCache: Discoveries?
    private var weeklyComparisonCache: WeeklyPlatformComparison?

    private let bluebirdAccountAPIService: BluebirdAccountAPIService
    private let supabaseManager = SupabaseClientManager.shared
    private let cacheManager = CacheManager.shared

    init(
        appState: AppState,
        bluebirdAccountAPIService: BluebirdAccountAPIService
    ) {
        self.appState = appState
        self.bluebirdAccountAPIService = bluebirdAccountAPIService
    }

    func getCurrentlyPlayingSong() -> String {
        return "\(appState.currentSong) - \(appState.currentArtist)"
    }

    func getPlaysPercentageChange() -> Double {
        let percentageChange: Double
        if lastWeekTotalPlays == 0 {
            percentageChange = thisWeekTotalPlays > 0 ? 100.0 : 0.0
        } else {
            percentageChange =
                ((Double(thisWeekTotalPlays) - Double(lastWeekTotalPlays))
                        / Double(lastWeekTotalPlays)) * 100
        }
        return percentageChange
    }
    
    func fetchHourlyPlaysMinutes() async {
        let currentHour = Calendar.current.component(.hour, from: Date())
        if let cached = hourlyPlaysMinutesCache,
           let cachedLastFetched = hourlyPlaysMinutesCacheHour,
           cachedLastFetched == currentHour {
                hourlyPlaysMinutes = cached
            return
        }
        if let cached = cacheManager.getHourlyPlaysMinutes() {
            let newHourlyPlaysMinutes = cached.map{$0.plays}
            hourlyPlaysMinutesCache = newHourlyPlaysMinutes
            hourlyPlaysMinutesCacheHour = currentHour
            hourlyPlaysMinutes = newHourlyPlaysMinutes
            return
        }
        let result = await bluebirdAccountAPIService.getHourlyPlaysMinutes()
        switch result {
        case let .success(result):
            let newHourlyPlaysMinutes = result.map{$0.plays}
            hourlyPlaysMinutes = newHourlyPlaysMinutes
            hourlyPlaysMinutesCache = newHourlyPlaysMinutes
            hourlyPlaysMinutesCacheHour = currentHour
            cacheManager.saveHourlyPlaysMinutes(result)
            print(hourlyPlaysMinutes)
        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("❌ [ERROR] Fetching hourly plays minutes: \(presentationError)")
            hourlyPlays = Array(repeating: 0, count: 24)
            appState.setError(presentationError)
        }
    }

    func fetchHourlyPlays(for days: Int) async {
        if let cached = hourlyPlaysCache[days] {
            print("📦 [CACHE HIT - Memory] Hourly plays for \(days) days")
            hourlyPlays = cached
            return
        }

        if let cached = cacheManager.getHourlyPlays(for: days) {
            print("💾 [CACHE HIT - SwiftData] Hourly plays for \(days) days")
            let playsArray = cached.reduce(into: Array(repeating: 0, count: 24)) {
                result, play in
                result[play.hour] = play.plays
            }
            hourlyPlays = playsArray
            hourlyPlaysCache[days] = playsArray // Save to memory cache
            return
        }

        // 3. Fetch from API
        print("🌐 [API CALL] Fetching hourly plays for \(days) days")
        let result = await bluebirdAccountAPIService.getHourlyPlays(for: days)
        switch result {
        case let .success(hourlyPlaysResponse):
            var newPlays = Array(repeating: 0, count: 24)
            for play in hourlyPlaysResponse {
                let hourIndex = play.hour
                guard hourIndex >= 0 && hourIndex < 24 else { continue }
                newPlays[hourIndex] = play.plays
            }
            hourlyPlays = newPlays
            hourlyPlaysCache[days] = newPlays // Save to memory cache
            cacheManager.saveHourlyPlays(hourlyPlaysResponse, days: days)
            print("✅ [SAVED] Hourly plays cached for \(days) days")

        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("❌ [ERROR] Fetching hourly plays: \(presentationError)")
            hourlyPlays = Array(repeating: 0, count: 24)
            appState.setError(presentationError)
        }
    }

    func fetchDailyPlays() async {
        // 1. Check in-memory cache first
        if let cached = dailyPlaysCache {
            print("📦 [CACHE HIT - Memory] Daily plays")
            dailyPlays = cached
            lastWeekTotalPlays = dailyPlays.reduce(0) { $0 + $1.last_week }
            thisWeekTotalPlays = dailyPlays.reduce(0) { $0 + $1.this_week }
            return
        }

        // 2. Check SwiftData cache
        if let cached = cacheManager.getDailyPlays() {
            print("💾 [CACHE HIT - SwiftData] Daily plays")
            dailyPlays = cached
            dailyPlaysCache = cached // Save to memory
            lastWeekTotalPlays = dailyPlays.reduce(0) { $0 + $1.last_week }
            thisWeekTotalPlays = dailyPlays.reduce(0) { $0 + $1.this_week }
            return
        }

        // 3. Fetch from API
        print("🌐 [API CALL] Fetching daily plays")
        let result = await bluebirdAccountAPIService.getDailyPlays()
        switch result {
        case let .success(dailyPlaysResponse):
            dailyPlays = dailyPlaysResponse
            dailyPlaysCache = dailyPlaysResponse // Save to memory
            lastWeekTotalPlays = dailyPlays.reduce(0) { $0 + $1.last_week }
            thisWeekTotalPlays = dailyPlays.reduce(0) { $0 + $1.this_week }
            cacheManager.saveDailyPlays(dailyPlaysResponse)
            print("✅ [SAVED] Daily plays cached")

        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("❌ [ERROR] Fetching daily plays: \(presentationError)")
            appState.setError(presentationError)
        }
    }

    func fetchTopArtists(for days: Int) async {
        // 1. Check in-memory cache first
        if let cached = topArtistsCache[days] {
            print("📦 [CACHE HIT - Memory] Top artists for \(days) days")
            topArtists = cached
            return
        }

        // 2. Check SwiftData cache
        if let cached = cacheManager.getTopArtists(for: days) {
            print("💾 [CACHE HIT - SwiftData] Top artists for \(days) days")
            topArtists = cached
            topArtistsCache[days] = cached // Save to memory
            return
        }

        // 3. Fetch from API
        print("🌐 [API CALL] Fetching top artists for \(days) days")
        let result = await bluebirdAccountAPIService.getTopArtists(for: days)
        switch result {
        case let .success(topArtistsResponse):
            if topArtistsResponse.artists.isEmpty {
                print("⚠️ No top artists found")
                return
            }
            topArtists = topArtistsResponse
            topArtistsCache[days] = topArtistsResponse // Save to memory
            cacheManager.saveTopArtists(topArtistsResponse, days: days)
            print("✅ [SAVED] Top artists cached for \(days) days")
        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("❌ [ERROR] Fetching top artists: \(presentationError)")
            appState.setError(presentationError)
        }
    }

    func fetchTopTracks(for days: Int) async {
        // 1. Check in-memory cache first
        if let cached = topTracksCache[days] {
            print("📦 [CACHE HIT - Memory] Top tracks for \(days) days")
            topTracks = cached
            return
        }

        // 2. Check SwiftData cache
        if let cached = cacheManager.getTopTracks(for: days) {
            print("💾 [CACHE HIT - SwiftData] Top tracks for \(days) days")
            topTracks = cached
            topTracksCache[days] = cached // Save to memory
            return
        }

        // 3. Fetch from API
        print("🌐 [API CALL] Fetching top tracks for \(days) days")
        let result = await bluebirdAccountAPIService.getTopTracks(for: days)
        switch result {
        case let .success(topTracksResponse):
            if topTracksResponse.tracks.isEmpty {
                print("⚠️ No top tracks found")
                return
            }
            topTracks = topTracksResponse
            topTracksCache[days] = topTracksResponse // Save to memory
            cacheManager.saveTopTracks(topTracksResponse, days: days)
            print("✅ [SAVED] Top tracks cached for \(days) days")

        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("❌ [ERROR] Fetching top tracks: \(presentationError)")
            appState.setError(presentationError)
        }
    }

    func loadUserEntityListens(
        for id: String,
        forDays days: Int,
        entityType: EntityType
    ) async -> Int? {
        let result = await bluebirdAccountAPIService.getEntityPlays(
            for: id,
            forDays: days,
            entityType: entityType
        )
        switch result {
        case let .success(plays):
            return plays
        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error loading user entity listens: \(presentationError)")
            appState.setError(presentationError)
            return nil
        }
    }

    func getTrackTrend(for trackID: String) async -> [DailyPlayCount]? {
        if let cachedTrend = trackTrendCache[trackID] {
            return cachedTrend
        }

        let result = await bluebirdAccountAPIService.getTrackTrend(for: trackID)
        switch result {
        case let .success(response):
            let trendData = fillGaps(in: response.trend)
            trackTrendCache[trackID] = trendData
            return trendData

        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print(
                "Error loading track trend for \(trackID): \(presentationError)"
            )
            appState.setError(presentationError)
            return nil
        }
    }

    private func fillGaps(in trend: [DailyPlayCount]) -> [DailyPlayCount] {
        guard !trend.isEmpty else { return [] }
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: trend.first!.day)
        let endDate = calendar.startOfDay(for: trend.last!.day)
        var filled: [DailyPlayCount] = []
        var currentDate = startDate
        while currentDate <= endDate {
            if let existing = trend.first(where: {
                calendar.isDate($0.day, inSameDayAs: currentDate)
            }) {
                filled.append(existing)
            } else {
                filled.append(DailyPlayCount(day: currentDate, count: 0))
            }
            currentDate = calendar.date(
                byAdding: .day,
                value: 1,
                to: currentDate
            )!
        }
        return filled
    }

    func getTrackLastPlayed(for trackID: String) async -> Date? {
        let result = await bluebirdAccountAPIService.getTrackLastPlayed(
            for: trackID
        )
        switch result {
        case let .success(response):
            guard let date = response else {
                return nil
            }
            return date
        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print(
                "Error loading track last played for \(trackID): \(presentationError)"
            )
            appState.setError(presentationError)
            return nil
        }
    }

    func getTrackRank(for trackID: String) async -> Int {
        let result = await bluebirdAccountAPIService.getTrackRank(
            for: trackID
        )
        switch result {
        case let .success(response):
            return response
        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print(
                "Error loading track user percentile for \(trackID): \(presentationError)"
            )
            appState.setError(presentationError)
            return -1
        }
    }

    func getLeaderboard(
        type: LeaderboardType,
        id: String,
        scope: LeaderboardScope = .global
    ) async -> LeaderboardResponse? {
        print("🌐 [API CALL] Fetching leaderboard for \(type.rawValue) \(id) (scope: \(scope.rawValue))")
        let result = await bluebirdAccountAPIService.getLeaderboard(
            type: type,
            id: id,
            scope: scope
        )
        switch result {
        case let .success(response):
            print("✅ [LEADERBOARD] Got \(response.leaderboard.count) entries")
            print("   Current user: \(response.current_user.profile.username) - \(response.current_user.play_count) plays")
            for (index, entry) in response.leaderboard.enumerated() {
                print("   #\(index + 1): \(entry.profile.username) - \(entry.play_count) plays")
            }
            return response
        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("❌ [ERROR] Fetching leaderboard: \(presentationError)")
            appState.setError(presentationError)
            return nil
        }
    }

    func fetchTopGenres(for days: Int) async {
        // 1. Check in-memory cache first
        if let cached = topGenresCache[days] {
            print("📦 [CACHE HIT - Memory] Top genres for \(days) days")
            topGenres = cached
            return
        }

        // 2. Check SwiftData cache
        if let cached = cacheManager.getTopGenres(for: days) {
            print("💾 [CACHE HIT - SwiftData] Top genres for \(days) days")
            topGenres = cached
            topGenresCache[days] = cached // Save to memory
            return
        }

        // 3. Fetch from API
        print("🌐 [API CALL] Fetching top genres for \(days) days")
        let result = await bluebirdAccountAPIService.getTopGenres(numDays: days)
        switch result {
        case let .success(response):
            topGenres = response
            topGenresCache[days] = response // Save to memory
            cacheManager.saveTopGenres(response, days: days)
            print("✅ [SAVED] Top genres cached for \(days) days")
        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("❌ [ERROR] Fetching top genres: \(presentationError)")
            appState.setError(presentationError)
            topGenres = GenreCounts()
        }
    }

    func fetchDiscoveredTracksArtists() async {
        // 1. Check in-memory cache first
        if let cached = discoveriesCache {
            print("📦 [CACHE HIT - Memory] Discoveries")
            discoveredTracks = cached.discovered_tracks
                .sorted { $0.play_count > $1.play_count }
                .prefix(3)
                .map { $0 }

            discoveredArtists = cached.discovered_artists
                .sorted { $0.play_count > $1.play_count }
                .prefix(3)
                .map { $0 }
            return
        }

        // 2. Check SwiftData cache
        if let cached = cacheManager.getDiscoveries() {
            print("💾 [CACHE HIT - SwiftData] Discoveries")
            discoveriesCache = cached // Save to memory
            discoveredTracks = cached.discovered_tracks
                .sorted { $0.play_count > $1.play_count }
                .prefix(3)
                .map { $0 }

            discoveredArtists = cached.discovered_artists
                .sorted { $0.play_count > $1.play_count }
                .prefix(3)
                .map { $0 }
            return
        }

        // 3. Fetch from API
        print("🌐 [API CALL] Fetching discoveries")
        let result = await bluebirdAccountAPIService.getDiscoveries()
        switch result {
        case let .success(discoveries):
            discoveriesCache = discoveries // Save to memory
            discoveredTracks = discoveries.discovered_tracks
                .sorted { $0.play_count > $1.play_count }
                .prefix(3)
                .map { $0 }

            discoveredArtists = discoveries.discovered_artists
                .sorted { $0.play_count > $1.play_count }
                .prefix(3)
                .map { $0 }

            cacheManager.saveDiscoveries(discoveries)
            print("✅ [SAVED] Discoveries cached")
        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("❌ [ERROR] Fetching discoveries: \(presentationError)")
            appState.setError(presentationError)
        }
    }

    func fetchWeeklyStatsComparison() async {
        // 1. Check in-memory cache first
        if let cached = weeklyComparisonCache {
            print("📦 [CACHE HIT - Memory] Weekly comparison")
            weeklyComparison = cached
            return
        }

        // 2. Check SwiftData cache
        if let cached = cacheManager.getWeeklyComparison() {
            print("💾 [CACHE HIT - SwiftData] Weekly comparison")
            weeklyComparison = cached
            weeklyComparisonCache = cached // Save to memory
            return
        }

        // 3. Fetch from API
        print("🌐 [API CALL] Fetching weekly comparison")
        let result = await bluebirdAccountAPIService.getWeeklyPlatformComparison()
        switch result {
        case let .success(comparison):
            weeklyComparison = comparison
            weeklyComparisonCache = comparison // Save to memory
            cacheManager.saveWeeklyComparison(comparison)
            print("✅ [SAVED] Weekly comparison cached")
        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("❌ [ERROR] Fetching weekly comparison: \(presentationError)")
            appState.setError(presentationError)
        }
    }
    
    func clearCaches() {
        hourlyPlaysCache.removeAll()
        topTracksCache.removeAll()
        topArtistsCache.removeAll()
        topGenresCache.removeAll()
        dailyPlaysCache = nil
        discoveriesCache = nil
        weeklyComparisonCache = nil
        trackTrendCache.removeAll()
    }
}
