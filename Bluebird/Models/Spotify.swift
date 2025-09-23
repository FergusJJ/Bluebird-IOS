import Foundation

struct ArtistDetail: Codable, Identifiable {
    var id: String { artist_id }
    let artist_id: String
    let name: String
    let followers: Int
    let spotify_uri: String
    let albums: [AlbumSummary]
    let top_tracks: [TopTrack]
}

struct AlbumDetail: Codable, Identifiable {
    var id: String { album_id }
    let album_id: String
    let name: String
    let artists: [SongDetailArtist]
    let image_url: String
    let release_date: String
    let total_tracks: Int
    let spotify_uri: String

    let tracks: [AlbumDetailTrack]
}

struct AlbumDetailTrack: Codable, Identifiable {
    let id: String
    let name: String
    let track_number: Int
}

struct AlbumSummary: Codable, Identifiable, Hashable {
    var id: String { album_id }
    let album_id: String
    let name: String
    let image_url: String
    let spotify_uri: String
    let artists: [SongDetailArtist]

    static func == (lhs: AlbumSummary, rhs: AlbumSummary) -> Bool {
        return lhs.album_id == rhs.album_id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/* struct Artist: Codable, Identifiable {
     let id: String
     let name: String
     let spotify_uri: String?
 } */

struct TopTrack: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let spotify_uri: String
    let image_url: String
}
