import SwiftUI

@MainActor
class StatsViewModel: ObservableObject, TryRequestViewModel, CachedViewModel {
    internal var appState: AppState

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
    let cacheManager = CacheManager.shared

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
            cachedLastFetched == currentHour
        {
            hourlyPlaysMinutes = cached
            return
        }
        if let cached = cacheManager.getHourlyPlaysMinutes() {
            let newHourlyPlaysMinutes = cached.map { $0.plays }
            hourlyPlaysMinutesCache = newHourlyPlaysMinutes
            hourlyPlaysMinutesCacheHour = currentHour
            hourlyPlaysMinutes = newHourlyPlaysMinutes
            return
        }

        if let result = await tryRequest(
            { await bluebirdAccountAPIService.getHourlyPlaysMinutes() },
            "Error fetching hourly plays minutes"
        ) {
            let newHourlyPlaysMinutes = result.map { $0.plays }
            hourlyPlaysMinutes = newHourlyPlaysMinutes
            hourlyPlaysMinutesCache = newHourlyPlaysMinutes
            hourlyPlaysMinutesCacheHour = currentHour
            cacheManager.saveHourlyPlaysMinutes(result)
        } else {
            hourlyPlays = Array(repeating: 0, count: 24)
        }
    }

    func fetchHourlyPlays(for days: Int) async {
        if let cached = hourlyPlaysCache[days] {
            hourlyPlays = cached
            return
        }

        if let hourlyPlaysResponse = await tryRequest(
            { await bluebirdAccountAPIService.getHourlyPlays(for: days) },
            "Error fetching hourly plays"
        ) {
            var newPlays = Array(repeating: 0, count: 24)
            for play in hourlyPlaysResponse {
                let hourIndex = play.hour
                guard hourIndex >= 0 && hourIndex < 24 else { continue }
                newPlays[hourIndex] = play.plays
            }
            hourlyPlays = newPlays
            hourlyPlaysCache[days] = newPlays
        } else {
            hourlyPlays = Array(repeating: 0, count: 24)
        }
    }

    func fetchDailyPlays() async {
        if let cached = dailyPlaysCache {
            dailyPlays = cached
            lastWeekTotalPlays = dailyPlays.reduce(0) { $0 + $1.last_week }
            thisWeekTotalPlays = dailyPlays.reduce(0) { $0 + $1.this_week }
            return
        }

        if let cached = cacheManager.getDailyPlays() {
            dailyPlays = cached
            dailyPlaysCache = cached
            lastWeekTotalPlays = dailyPlays.reduce(0) { $0 + $1.last_week }
            thisWeekTotalPlays = dailyPlays.reduce(0) { $0 + $1.this_week }
            return
        }

        if let dailyPlaysResponse = await tryRequest(
            { await bluebirdAccountAPIService.getDailyPlays() },
            "Error fetching daily plays"
        ) {
            dailyPlays = dailyPlaysResponse
            dailyPlaysCache = dailyPlaysResponse
            lastWeekTotalPlays = dailyPlays.reduce(0) { $0 + $1.last_week }
            thisWeekTotalPlays = dailyPlays.reduce(0) { $0 + $1.this_week }
            cacheManager.saveDailyPlays(dailyPlaysResponse)
        }
    }

    func fetchTopArtists(for days: Int, forceRefresh: Bool = false) async {
        if !forceRefresh, let cached = topArtistsCache[days] {
            topArtists = cached
            return
        }

        if let response = await tryRequest(
            { await bluebirdAccountAPIService.getTopArtists(for: days) },
            "Error fetching top artists"
        ) {
            if response.artists.isEmpty {
                return
            }
            topArtists = response
            topArtistsCache[days] = response
        }
    }

    func fetchTopTracks(for days: Int, forceRefresh: Bool = false) async {
        if !forceRefresh, let cached = topTracksCache[days] {
            topTracks = cached
            return
        }

        if let response = await tryRequest(
            { await bluebirdAccountAPIService.getTopTracks(for: days) },
            "Error fetching top tracks"
        ) {
            if response.tracks.isEmpty {
                return
            }
            topTracks = response
            topTracksCache[days] = response
        }
    }

    func loadUserEntityListens(
        for id: String,
        forDays days: Int,
        entityType: EntityType
    ) async -> Int? {
        return await tryRequest(
            {
                await bluebirdAccountAPIService.getEntityPlays(
                    for: id, forDays: days, entityType: entityType)
            },
            "Error fetching entity plays"
        )
    }

    func getTrackTrend(for trackID: String) async -> [DailyPlayCount]? {
        if let cachedTrend = trackTrendCache[trackID] {
            return cachedTrend
        }

        if let response = await tryRequest(
            { await bluebirdAccountAPIService.getTrackTrend(for: trackID) },
            "Error fetching track trend for \(trackID)"
        ) {
            let trendData = fillGaps(in: response.trend)
            trackTrendCache[trackID] = trendData
            return trendData
        }
        return nil
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
        if let response = await tryRequest(
            { await bluebirdAccountAPIService.getTrackLastPlayed(for: trackID) },
            "Error fetching track last played for \(trackID)"
        ) {
            return response
        }
        return nil
    }

    func getTrackRank(for trackID: String) async -> Int {
        if let response = await tryRequest(
            { await bluebirdAccountAPIService.getTrackRank(for: trackID) },
            "Error fetching track rank for \(trackID)"
        ) {
            return response
        }
        return -1
    }

    func getLeaderboard(
        type: LeaderboardType,
        id: String,
        scope: LeaderboardScope = .global
    ) async -> LeaderboardResponse? {
        if let response = await tryRequest(
            { await bluebirdAccountAPIService.getLeaderboard(type: type, id: id, scope: scope) },
            "Error fetching leaderboard"
        ) {
            print("Got \(response.leaderboard.count) entries")
            print(
                "Current user: \(response.current_user.profile.username) - \(response.current_user.play_count) plays"
            )
            for (index, entry) in response.leaderboard.enumerated() {
                print("#\(index + 1): \(entry.profile.username) - \(entry.play_count) plays")
            }
            return response
        }
        return nil
    }

    func fetchTopGenres(for days: Int) async {
        if let cached = topGenresCache[days] {
            topGenres = cached
            return
        }

        if let response = await tryRequest(
            { await bluebirdAccountAPIService.getTopGenres(numDays: days) },
            "Error fetching top genres"
        ) {
            topGenres = response
            topGenresCache[days] = response
        } else {
            topGenres = GenreCounts()
        }
    }

    func fetchDiscoveredTracksArtists() async {
        if let cached = discoveriesCache {
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

        if let cached = cacheManager.getDiscoveries() {
            discoveriesCache = cached
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

        if let discoveries = await tryRequest(
            { await bluebirdAccountAPIService.getDiscoveries() },
            "Error fetching discoveries"
        ) {
            discoveriesCache = discoveries
            discoveredTracks = discoveries.discovered_tracks
                .sorted { $0.play_count > $1.play_count }
                .prefix(3)
                .map { $0 }

            discoveredArtists = discoveries.discovered_artists
                .sorted { $0.play_count > $1.play_count }
                .prefix(3)
                .map { $0 }

            cacheManager.saveDiscoveries(discoveries)
        }
    }

    func fetchWeeklyStatsComparison() async {
        if let cached = weeklyComparisonCache {
            weeklyComparison = cached
            return
        }

        if let cached = cacheManager.getWeeklyComparison() {
            weeklyComparison = cached
            weeklyComparisonCache = cached
            return
        }

        if let comparison = await tryRequest(
            { await bluebirdAccountAPIService.getWeeklyPlatformComparison() },
            "Error fetching weekly comparison"
        ) {
            weeklyComparison = comparison
            weeklyComparisonCache = comparison
            cacheManager.saveWeeklyComparison(comparison)
        }
    }

}
