struct CurrentlyPlayingResponse: Decodable {
    let tracks: [String: SongDetail]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        tracks = try container.decode([String: SongDetail].self)
    }

    // Get all user IDs that have tracks
    var userIds: [String] {
        return Array(tracks.keys)
    }
}
