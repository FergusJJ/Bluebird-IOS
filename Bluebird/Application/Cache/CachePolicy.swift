import Foundation

/// durations in seconds
enum CacheTTL {
    static let profile: TimeInterval = 300
    static let friends: TimeInterval = 300
    static let stats: TimeInterval = 3600
    static let songHistory: TimeInterval = 600
    static let socialProfile: TimeInterval = 300
    static let milestones: TimeInterval = 3600
    static let pins: TimeInterval = 0
}
