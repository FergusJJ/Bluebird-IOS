import SwiftUI // Import Foundation for LocalizedError

enum APIError: Error, LocalizedError {
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

    case unknownError // catchall
    case noResponse

    var errorDescription: String? {
        switch self {
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
            let baseMessage = "The server returned an error (\(statusCode))."
            return message != nil ? "\(baseMessage) Details: \(message!)" : baseMessage
        case let .badRequest(message):
            let baseMessage = "The request was malformed (400 Bad Request)."
            return message != nil ? "\(baseMessage) Details: \(message!)" : baseMessage
        case .unauthorized:
            return "You are not authorized to perform this action. Please log in again."
        case .forbidden:
            return "You do not have permission to access this resource (403 Forbidden)."
        case .notFound:
            return "The requested resource was not found (404 Not Found)."
        case let .conflict(message):
            let baseMessage =
                "A conflict occurred with the current state of the resource (409 Conflict)."
            return message != nil ? "\(baseMessage) Details: \(message!)" : baseMessage
        case let .encodingError(error):
            return "Failed to prepare data for the request: \(error.localizedDescription)"
        case let .decodingError(error):
            return "Failed to understand the server's response: \(error.localizedDescription)"
        case .unknownError:
            return "An unexpected error occurred. Please try again later."
        case .noResponse:
            return "The server did not send any response."
        }
    }
}
