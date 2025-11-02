import SwiftUI

enum BluebirdAPIError: Error {
    case networkError(Error)
    case invalidEndpoint
    case decodingError(statusCode: Int, error: Error)
    case encodingError(Error)
    case apiError(statusCode: Int, message: String?)
    case notAuthenticated
    case notFound
    case spotifyAPIError
    case invalidResponse
    case unknownError
    case requestCancelled

    var errorDescription: String? {
        switch self {
        case let .networkError(error):
            if let urlError = error as? URLError {
                return "Network connection problem: \(urlError.localizedDescription)"
            }
            return "A network error occurred: \(error.localizedDescription)"
        case .invalidEndpoint:
            return "The API endpoint is misconfigured. Please contact support."
        case let .decodingError(statusCode, error):
            return
                "Failed to process server response (\(statusCode)): \(error.localizedDescription)"
        case let .encodingError(error):
            return "Failed to prepare request data: \(error.localizedDescription)"
        case let .apiError(statusCode, message):
            var baseMessage = "Server responded with an error (\(statusCode))."
            if let details = message {
                baseMessage += " Details: \(details)"
            }
            return baseMessage
        case .notAuthenticated:
            return "You are not authenticated. Please log in again."
        case .notFound:
            return "The requested resource was not found."
        case .spotifyAPIError:
            return "An error occurred with the Spotify API integration."
        case .invalidResponse:
            return "Invalid response received from server."
        case .unknownError:
            return "An unexpected error occurred. Please try again."
        case .requestCancelled:
            return "The request was cancelled."
        }
    }
}
