import SwiftUI

enum SignUpError: Error, LocalizedError {
    case authFailed(Error)
    case profileInsertFailed(Error)

    var errorDescription: String? {
        switch self {
        case let .authFailed(error):
            // Provide a user-friendly message, potentially hiding internal details
            return "Sign up failed. Please check your details and try again. (\(error.localizedDescription))"
        case let .profileInsertFailed(error):
            // This might indicate a server-side issue
            return "Failed to create user profile after sign up. Please contact support. (\(error.localizedDescription))"
        }
    }
}

enum SignOutError: Error, LocalizedError {
    case unexpectedError

    var errorDescription: String? {
        switch self {
        case .unexpectedError:
            return "An unexpected error occurred during sign out."
        }
    }
}

enum DatabaseError: Error, LocalizedError {
    case uploadFailed(Error)
    // Add other DB errors like fetchFailed, deleteFailed if needed

    var errorDescription: String? {
        switch self {
        case let .uploadFailed(error):
            return "Database operation failed: \(error.localizedDescription)"
        }
    }
}
