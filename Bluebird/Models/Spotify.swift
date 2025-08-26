import Foundation

protocol DisplayableSong {
    var trackName: String { get }
    var artistName: String { get }
    var imageURL: String { get }
}

struct CurrentlyPlayingSongResponse: Decodable {
    let trackName: String
    let artistNames: [String]
    let imageUrl: String
    enum CodingKeys: String, CodingKey {
        case trackName = "track_name"
        case artistNames = "artist_names"
        case imageUrl = "image_url"
    }
}

struct ViewSongExt: Identifiable, Decodable, DisplayableSong {
    let id = UUID()

    let trackName: String
    let artistName: String
    let albumName: String
    let durationMillis: Int
    let imageURL: String
    let spotifyURL: String
    let listenedAt: Int
    enum CodingKeys: String, CodingKey {
        case trackName
        case artistName
        case albumName
        case durationMillis = "durationMs"
        case imageURL = "imageUrl"
        case spotifyURL = "spotifyUrl"
        case listenedAt
    }
}

struct ViewSong: DisplayableSong {
    let song: String
    let artists: String
    let imageUrl: String

    var trackName: String { song }
    var artistName: String { artists }
    var imageURL: String { imageUrl }
}
