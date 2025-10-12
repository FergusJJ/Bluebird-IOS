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

    init(
        track_id: String = "",
        album_id: String = "",
        name: String = "",
        artists: [SongDetailArtist] = [],
        duration_ms: Int = 0,
        spotify_url: String = "",
        album_name: String = "",
        album_image_url: String = "",
        listened_at: Int? = nil
    ) {
        self.track_id = track_id
        self.album_id = album_id
        self.name = name
        self.artists = artists
        self.duration_ms = duration_ms
        self.spotify_url = spotify_url
        self.album_name = album_name
        self.album_image_url = album_image_url
        self.listened_at = listened_at
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        track_id = try container.decodeIfPresent(String.self, forKey: .track_id) ?? ""
        album_id = try container.decodeIfPresent(String.self, forKey: .album_id) ?? ""
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        artists = try container.decodeIfPresent([SongDetailArtist].self, forKey: .artists) ?? []
        duration_ms = try container.decodeIfPresent(Int.self, forKey: .duration_ms) ?? 0
        spotify_url = try container.decodeIfPresent(String.self, forKey: .spotify_url) ?? ""
        album_name = try container.decodeIfPresent(String.self, forKey: .album_name) ?? ""
        album_image_url = try container.decodeIfPresent(String.self, forKey: .album_image_url) ?? ""
        listened_at = try container.decodeIfPresent(Int.self, forKey: .listened_at)
    }
}

extension SongDetail {
    var isEmpty: Bool {
        return track_id.isEmpty &&
            album_id.isEmpty &&
            name.isEmpty &&
            artists.isEmpty &&
            duration_ms == 0 &&
            spotify_url.isEmpty &&
            album_name.isEmpty &&
            album_image_url.isEmpty
    }
}
