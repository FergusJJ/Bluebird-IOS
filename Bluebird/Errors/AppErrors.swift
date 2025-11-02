import SwiftUI // Import Foundation for LocalizedError

enum AppError: Error, LocalizedError, Identifiable, Equatable {
    var id: String { localizedDescription }

    static func == (lhs: AppError, rhs: AppError) -> Bool {
        lhs.id == rhs.id
    }

    init(from supabaseError: SupabaseError) {
        switch supabaseError {
        case let .signupFailed(error):
            self = .signupFailed(error.localizedDescription)
        case let .loginFailed(error):
            self = .loginFailed(error.localizedDescription)
        case let .logoutFailed(error):
            self = .logoutFailed(error.localizedDescription)
        case let .deleteAccountFailed(error):
            self = .deleteAccountFailed(error.localizedDescription)
        case let .storageError(error):
            self = .storageError(error.localizedDescription)
        case .unacceptableStatusCode:
            self = .unacceptableStatusCode
        case .genericError:
            self = .genericSupabaseError
        }
    }

    init(from appStateError: AppStateError) {
        switch appStateError {
        case .userNotLoggedIn:
            self = .unauthorized

        case .keychainError, .missingUserID, .genericError:
            self = .internalStateError(appStateError)
        }
    }

    // some of these will be unused and removed
    init(from serviceError: BluebirdAPIError) {
        switch serviceError {
        case let .networkError(error):
            self = .networkError(error)

        case .invalidEndpoint:
            self = .endpointError

        case let .decodingError(_, error):
            self = .decodingError(error)

        case let .encodingError(error):
            self = .encodingError(error)

        case .notAuthenticated:
            self = .unauthorized

        case .notFound:
            self = .notFound

        case let .apiError(statusCode, message):
            switch statusCode {
            case 401:
                self = .unauthorized
            case 403:
                self = .forbidden
            case 404:
                self = .notFound
            default:
                self = .serverError(statusCode: statusCode, message: message)
            }

        case .spotifyAPIError:
            self = .serverError(
                statusCode: 502, message: "A problem occurred while communicating with Spotify."
            )

        case .invalidResponse:
            self = .invalidResponse

        case .unknownError:
            self = .unknownError
        case .requestCancelled:
            self = .requestCancelled
        }
    }

    // SupabaseErrors
    case signupFailed(String)
    case loginFailed(String)
    case logoutFailed(String)
    case deleteAccountFailed(String)
    case storageError(String)
    case unacceptableStatusCode
    case genericSupabaseError

    // API/App State Errors
    case internalStateError(Error)
    case invalidURL
    case networkError(Error)
    case endpointError

    case serverError(statusCode: Int, message: String?)
    case badRequest(message: String?)
    case forbidden
    case unauthorized
    case notFound
    case conflict(message: String?)

    case encodingError(Error)
    case decodingError(Error)

    case invalidResponse
    case requestCancelled
    case unknownError // catchall
    case noResponse

    var errorDescription: String? {
        switch self {
        case let .signupFailed(reason):
            return "An error occurred during sign up. \(reason)"
        case let .loginFailed(reason):
            return "An error occurred whilst logging in. \(reason)"
        case let .logoutFailed(reason):
            return "An error occurred whilst logging out. \(reason)"
        case let .deleteAccountFailed(reason):
            return "An error occurred whilste deleting account. \(reason)"
        case let .storageError(reason):
            return "An error occurred whilst uploading asset. \(reason)"
        case .unacceptableStatusCode:
            return "Bad response received whilst reading database."
        case .genericSupabaseError:
            return "An error occurred whilst performing the requested action."
        case let .internalStateError(error):
            return "An internal application error occurred: \(error.localizedDescription)"
        case .invalidURL:
            return "The request could not be sent because the URL is invalid."
        case let .networkError(error):
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    return "You are not connected to the internet. Please check your connection."
                case .timedOut:
                    return "The network request timed out. Please try again."
                case .cannotFindHost, .cannotConnectToHost:
                    return
                        "Could not connect to the server. The server might be down or unreachable."
                default:
                    return "A network error occurred: \(urlError.localizedDescription)"
                }
            }
            return "A network error occurred: \(error.localizedDescription)"
        case .endpointError:
            return "The API endpoint could not be properly constructed or is invalid."
        case let .serverError(statusCode, message):
            var baseMessage = "The server returned an error (\(statusCode))."
            if let details = message {
                baseMessage += " Details: \(details)"
            }
            return baseMessage
        case let .badRequest(message):
            var baseMessage = "The request was malformed (400 Bad Request)."
            if let details = message {
                baseMessage += " Details: \(details)"
            }
            return baseMessage
        case .unauthorized:
            return "You are not authorized to perform this action. Please log in again."
        case .forbidden:
            return "You do not have permission to access this resource (403 Forbidden)."
        case .notFound:
            return "The requested resource was not found (404 Not Found)."
        case let .conflict(message):
            var baseMessage =
                "A conflict occurred with the current state of the resource (409 Conflict)."
            if let details = message {
                baseMessage += " Details: \(details)"
            }
            return baseMessage
        case let .encodingError(error):
            return "Failed to prepare data for the request: \(error.localizedDescription)"
        case let .decodingError(error):
            return "Failed to understand the server's response: \(error.localizedDescription)"
        case .invalidResponse:
            return "An invalid response was received from the server."
        case .requestCancelled:
            return "The request was cancelled."
        case .unknownError:
            return "An unexpected error occurred. Please try again later."
        case .noResponse:
            return "The server did not send any response."
        }
    }

    var presentationStyle: ErrorPresentationStyle {
        switch self {
        case .signupFailed, .loginFailed:
            return .inline
        default:
            return .generic
        }
    }
}

enum ErrorPresentationStyle: Equatable {
    case generic // Global pop-up alerts
    case inline
}
