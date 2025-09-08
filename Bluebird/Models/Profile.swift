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
