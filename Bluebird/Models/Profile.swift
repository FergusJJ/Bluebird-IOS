import Foundation

struct SignUpProfile: Encodable {
    let id: UUID
    let username: String
}

struct UpdateProfileRequest: Encodable {
    let username: String?
    let bio: String?
    let avatarUrl: String?
}

struct ProfileInfo: Decodable {
    let message: String
    let username: String
    let bio: String
    let avatarUrl: String
}

struct HeadlineViewStats: Decodable {
    let total_plays: Int
    let unique_artists: Int
    let total_duration_millis: Int
}

struct ScrollViewObject: Identifiable {
    let id = UUID()
    let imageURL: URL
    let name: String
}

// MARK: - Pin stuff

enum EntityType: String, Codable {
    case artist, album, track
}

extension EntityType {
    init?(safeRawValue: String) {
        self.init(rawValue: safeRawValue.lowercased())
    }
}

struct Pin: Decodable, Hashable {
    let entity_id: String
    let entity_type: EntityType
    var id: String { "\(entity_id)_\(entity_type)" }
}

struct GetPinsResponse: Decodable {
    let pins: [Pin]
    let total: Int
    let query: String
}

struct GetEntityDetailsResponse: Decodable {
    let tracks: [SongDetail]
    let albums: [AlbumDetail]
    let artists: [ArtistDetail]
}
