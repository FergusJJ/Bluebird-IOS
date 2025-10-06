import SwiftUI

@MainActor
class StatsViewModel: ObservableObject {
    private var appState: AppState

    @Published var hourlyPlays: [Int] = Array(repeating: 0, count: 24)
    @Published var dailyPlays: [DailyPlay] = []
    @Published var topTracks: TopTracks = .init(tracks: [:])
    @Published var topArtists: TopArtists = .init(artists: [:])
    @Published var topGenres: GenreCounts = .init()

    @Published var discoveredArtists: [ArtistWithPlayCount] = []
    @Published var discoveredTracks: [TrackWithPlayCount] = []

    @Published var trackTrendCache: [String: [DailyPlayCount]] = [:]

    @Published var lastWeekTotalPlays: Int = 0
    @Published var thisWeekTotalPlays: Int = 0

    private var hourlyPlaysCache: [Int: [Int]] = [:]
    private var topTracksCache: [Int: TopTracks] = [:]
    private var topArtistsCache: [Int: TopArtists] = [:]
    private var topGenresCache: [Int: GenreCounts] = [:]

    private let bluebirdAccountAPIService: BluebirdAccountAPIService
    private let supabaseManager = SupabaseClientManager.shared

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

    func fetchHourlyPlays(for days: Int) async {
        if let cached = hourlyPlaysCache[days] {
            hourlyPlays = cached
            return
        }
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
            hourlyPlaysCache[days] = newPlays

        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error fetching hourly plays: \(presentationError)")
            hourlyPlays = Array(repeating: 0, count: 24)
            appState.setError(presentationError)
        }
    }

    func fetchDailyPlays() async {
        let result = await bluebirdAccountAPIService.getDailyPlays()
        switch result {
        case let .success(dailyPlaysResponse):
            dailyPlays = dailyPlaysResponse
            lastWeekTotalPlays = dailyPlays.reduce(0) { $0 + $1.last_week }
            thisWeekTotalPlays = dailyPlays.reduce(0) { $0 + $1.this_week }

        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error fetching daily plays: \(presentationError)")
            appState.setError(presentationError)
        }
    }

    func fetchTopArtists(for days: Int) async {
        if let cached = topArtistsCache[days] {
            topArtists = cached
            return
        }
        let result = await bluebirdAccountAPIService.getTopArtists(for: days)
        switch result {
        case let .success(topArtistsResponse):
            guard let topArtistsPresent = topArtistsResponse else {
                print("No top artists")
                return
            }
            topArtists = topArtistsPresent
            topArtistsCache[days] = topArtistsPresent
        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error top artists: \(presentationError)")
            appState.setError(presentationError)
        }
    }

    func fetchTopTracks(for days: Int) async {
        if let cached = topTracksCache[days] {
            topTracks = cached
            return
        }
        let result = await bluebirdAccountAPIService.getTopTracks(for: days)
        switch result {
        case let .success(topTracksResponse):
            guard let topTracksPresent = topTracksResponse else {
                print("No top tracks")
                return
            }
            topTracks = topTracksPresent
            topTracksCache[days] = topTracksPresent
            return

        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error top tracks: \(presentationError)")
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

    func getTrackUserPercentile(for trackID: String) async -> Double {
        let result = await bluebirdAccountAPIService.getTrackUserPercentile(
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
            return 0.0
        }
    }

    func fetchTopGenres(for days: Int) async {
        if let cached = topGenresCache[days] {
            topGenres = cached
            return
        }

        let result = await bluebirdAccountAPIService.getTopGenres(numDays: days)
        switch result {
        case let .success(response):
            topGenres = response
            topGenresCache[days] = response
        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error loading top genres: \(presentationError)")
            appState.setError(presentationError)
            topGenres = GenreCounts()
        }
    }

    func fetchDiscoveredTracksArtists() async {
        let result = await bluebirdAccountAPIService.getDiscoveries()
        switch result {
        case let .success(discoveries):
            discoveredTracks = discoveries.discovered_tracks
            discoveredArtists = discoveries.discovered_artists
        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error loading discoveries: \(presentationError)")
            appState.setError(presentationError)
        }
    }
}
