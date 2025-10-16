import Foundation

struct HourlyPlay: Codable {
    let hour: Int
    let plays: Int
}

struct DailyPlay: Codable {
    let day_of_week: Int
    let this_week: Int
    let last_week: Int
}

struct ArtistWithPlayCount: Codable, Hashable {
    let artist: ArtistDetail
    let play_count: Int

    static func == (lhs: ArtistWithPlayCount, rhs: ArtistWithPlayCount) -> Bool {
        lhs.artist.artist_id == rhs.artist.artist_id
            && lhs.play_count == rhs.play_count
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(artist.artist_id)
        hasher.combine(play_count)
    }
}

struct TopArtists: Codable, Hashable {
    let artists: [Int: ArtistWithPlayCount]

    init(artists: [Int: ArtistWithPlayCount]) {
        self.artists = artists
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        artists = try container.decode([Int: ArtistWithPlayCount].self)
    }

    static func == (lhs: TopArtists, rhs: TopArtists) -> Bool {
        lhs.artists.keys.sorted() == rhs.artists.keys.sorted()
            && lhs.artists.keys.allSatisfy { key in
                lhs.artists[key] == rhs.artists[key]
            }
    }

    func hash(into hasher: inout Hasher) {
        for (key, value) in artists.sorted(by: { $0.key < $1.key }) {
            hasher.combine(key)
            hasher.combine(value)
        }
    }
}

struct TrackWithPlayCount: Codable, Hashable {
    let track: SongDetail
    let play_count: Int

    static func == (lhs: TrackWithPlayCount, rhs: TrackWithPlayCount) -> Bool {
        lhs.track.track_id == rhs.track.track_id
            && lhs.play_count == rhs.play_count
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(track.track_id)
        hasher.combine(play_count)
    }
}

struct TopTracks: Codable, Hashable {
    let tracks: [Int: TrackWithPlayCount]

    init(tracks: [Int: TrackWithPlayCount]) {
        self.tracks = tracks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        tracks = try container.decode([Int: TrackWithPlayCount].self)
    }

    static func == (lhs: TopTracks, rhs: TopTracks) -> Bool {
        lhs.tracks.keys.sorted() == rhs.tracks.keys.sorted()
            && lhs.tracks.keys.allSatisfy { key in
                lhs.tracks[key] == rhs.tracks[key]
            }
    }

    func hash(into hasher: inout Hasher) {
        for (key, value) in tracks.sorted(by: { $0.key < $1.key }) {
            hasher.combine(key)
            hasher.combine(value)
        }
    }
}

// used for listening history for specific track/artist/album
struct DailyPlayCount: Decodable, Identifiable {
    var id: Date { day }
    let day: Date
    let count: Int

    init(day: Date, count: Int) {
        self.day = day
        self.count = count
    }
}

struct TrackTrendResponse: Decodable {
    let trend: [DailyPlayCount]
}

struct TrackLastPlayedResponse: Decodable {
    let last_played: Date?
}

struct TrackUserPercentile: Decodable {
    let percentile: Double
}

typealias GenreCounts = [String: Int]

struct Discoveries: Codable {
    let discovered_tracks: [TrackWithPlayCount]
    let discovered_artists: [ArtistWithPlayCount]
}

struct WeeklyPlatformComparison: Codable {
    let tracks: Int
    let artists: Int
    let albums: Int
    let tracks_percentile: Float64
    let artists_percentile: Float64
    let albums_percentile: Float64

    init(
        tracks: Int = 0,
        artists: Int = 0,
        albums: Int = 0,
        tracks_percentile: Float64 = 0,
        artists_percentile: Float64 = 0,
        albums_percentile: Float64 = 0
    ) {
        self.tracks = tracks
        self.artists = artists
        self.albums = albums
        self.tracks_percentile = tracks_percentile
        self.artists_percentile = artists_percentile
        self.albums_percentile = albums_percentile
    }
}
