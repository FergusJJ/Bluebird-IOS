import Foundation
import Supabase

enum SignUpError: Error, LocalizedError {
    case authFailed(Error)
    case missingUserID
    case profileInsertFailed(Error)
    case profileInsertUnexpectedStatusCode(Int)
    case couldNotParseResponseDetails

    var errorDescription: String? {
        switch self {
        case let .authFailed(underlyingError):
            return "Authentication sign up failed: \(underlyingError.localizedDescription)"
        case .missingUserID:
            return "Sign up succeeded but no user ID was returned."
        case let .profileInsertFailed(underlyingError):
            // Check if it's a PostgrestError for more details
            if let pgError = underlyingError as? PostgrestError {
                return
                    "Failed to create user profile: \(pgError.message ?? pgError.localizedDescription)"
                        + "(Hint: \(pgError.hint ?? "None"), Code: \(pgError.code ?? "N/A"))"
            }
            return "Failed to create user profile: \(underlyingError.localizedDescription)"
        case let .profileInsertUnexpectedStatusCode(code):
            return "Profile creation returned unexpected status code: \(code)."
        case .couldNotParseResponseDetails:
            return "Could not parse HTTP response details after profile creation attempt."
        }
    }
}

enum QueryError: Error, LocalizedError {
    case unexpectedStatusCode(Int)
    var errorDescription: String? {
        switch self {
        case let .unexpectedStatusCode(code):
            return "Query returned unexpected status code: \(code)."
        }
    }
}
