import SwiftUI

enum SupabaseError: Error, LocalizedError {
    case signupFailed(Error)
    case loginFailed(Error)
    case logoutFailed(Error)
    case unacceptableStatusCode(Int)
    case genericError(Error)

    var errorDescription: String? {
        switch self {
        case let .signupFailed(error):
            return "Sign up failed: \(error.localizedDescription)"
        case let .loginFailed(error):
            return "Login failed: \(error.localizedDescription)"
        case let .logoutFailed(error):
            return "Logout failed: \(error.localizedDescription)"
        case let .unacceptableStatusCode(statusCode):
            return "Unacceptable status code from supaBase: \(statusCode)"
        case let .genericError(error):
            return "An error occurred: \(error.localizedDescription)"
        }
    }
}
