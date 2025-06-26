import SwiftUI // Import Foundation for LocalizedError

enum APIError: Error, LocalizedError {
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
        }
    }

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
    case unknownError // catchall
    case noResponse

    var errorDescription: String? {
        switch self {
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
        case .unknownError:
            return "An unexpected error occurred. Please try again later."
        case .noResponse:
            return "The server did not send any response."
        }
    }
}
