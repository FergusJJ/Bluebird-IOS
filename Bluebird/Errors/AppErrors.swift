import SwiftUI

enum AppStateError: Error, LocalizedError {
    case userNotLoggedIn
    case keychainError(String)
    case missingUserID
    case genericError(String)

    var errorDescription: String? {
        switch self {
        case .userNotLoggedIn:
            return "User is not logged in."
        case let .keychainError(message):
            return "A keychain operation failed: \(message)"
        case .missingUserID:
            return "Could not determine the current user ID."
        case let .genericError(message):
            return message
        }
    }
}
