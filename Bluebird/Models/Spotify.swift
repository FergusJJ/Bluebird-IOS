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

struct ViewSong {
    let song: String
    let artists: String
    let imageUrl: String
}
