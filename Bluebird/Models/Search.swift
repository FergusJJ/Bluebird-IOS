import Foundation

struct SearchSongResult: Decodable {
    let tracks: [SongDetail]
    let total: Int
    let query: String
}

struct SongDetailArtist: Encodable, Decodable, Identifiable {
    let id: String
    let image_url: String
    let name: String
}

struct SongDetail: Encodable, Decodable, Identifiable, Hashable {
    let track_id: String
    let album_id: String
    let name: String
    let artists: [SongDetailArtist]
    let duration_ms: Int
    let spotify_url: String
    let album_name: String
    let album_image_url: String
    let listened_at: Int?

    var id: String {
        if let ts = listened_at {
            return "\(track_id)-\(ts)"
        } else {
            return "\(track_id)-\(UUID().uuidString)"
        }
    }

    static func == (lhs: SongDetail, rhs: SongDetail) -> Bool {
        return lhs.track_id == rhs.track_id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
