import Foundation
import UIKit

struct SpotifyRefreshResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}

struct APIErrorResponse: Decodable {
    let error: String
}

enum BluebirdInitializationError: Error, LocalizedError {
    case missingCredentialsPlist
    case invalidCredentialsFormat
    case missingAPIURLKey
    case invalidAPIURL(String)

    var errorDescription: String? {
        switch self {
        case .missingCredentialsPlist:
            return "Configuration Error: APICredentials.plist not found in the main bundle."
        case .invalidCredentialsFormat:
            return "Configuration Error: APICredentials.plist is not in a valid dictionary format."
        case .missingAPIURLKey:
            return "Configuration Error: The 'API_URL' key was not found in APICredentials.plist."
        case let .invalidAPIURL(urlString):
            return
                "Configuration Error: The API_URL string '\(urlString)' in APICredentials.plist is not a valid URL."
        }
    }
}

enum BluebirdAPIError: Error {
    case networkError(Error)
    case invalidEndpoint
    case decodingError(Error)
    case apiError(statusCode: Int, message: String?)
    case notAuthenticated
    case unknownError
}

class BluebirdAPIManager {
    private let apiURL: URL

    init() throws {
        guard let path = Bundle.main.path(forResource: "APICredentials", ofType: "plist") else {
            throw BluebirdInitializationError.missingCredentialsPlist
        }
        guard let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject] else {
            throw BluebirdInitializationError.invalidCredentialsFormat
        }
        guard let apiURLString = dict["API_URL"] as? String else {
            throw BluebirdInitializationError.missingAPIURLKey
        }
        let cleanedApiURLString =
            apiURLString.hasSuffix("/") ? String(apiURLString.dropLast()) : apiURLString

        guard let validURL = URL(string: cleanedApiURLString) else {
            throw BluebirdInitializationError.invalidAPIURL(cleanedApiURLString)
        }
        apiURL = validURL
    }

    @MainActor
    func initiateSpotifyConnection() async -> Result<Void, BluebirdAPIError> {
        guard var components = URLComponents(url: apiURL, resolvingAgainstBaseURL: true) else {
            print("Error: Could not create URLComponents from base URL: \(apiURL)")
            return .failure(.invalidEndpoint)
        }

        components.path = apiURL.appendingPathComponent("/auth/spotify/login").path

        guard let finalURL = components.url else {
            print("Error: Could not create final URL from URLComponents: \(components)")
            return .failure(.invalidEndpoint)
        }
        print("Constructed Spotify Auth URL: \(finalURL.absoluteString)")
        guard UIApplication.shared.canOpenURL(finalURL) else {
            print(
                "Error: Cannot open the constructed URL. Check scheme validity and device capabilities."
            )
            return .failure(.invalidEndpoint)
        }
        await UIApplication.shared.open(finalURL)
        return .success(())
    }

    func refreshSpotifyAccessToken() async -> Result<String, BluebirdAPIError> {
        guard var components = URLComponents(url: apiURL, resolvingAgainstBaseURL: true) else {
            return .failure(.invalidEndpoint)
        }

        let refreshPath = "/api/spotify/refresh"
        components.path = refreshPath
        guard let url = components.url else {
            return .failure(.invalidEndpoint)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        print("attempting to het api token from supabase")
        if let session = try? await SupabaseClientManager.shared.client.auth.session {
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            return .failure(.notAuthenticated)
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Refresh Error: Invalid response type")
                return .failure(.unknownError)
            }

            print("Refresh Token Response Status: \(httpResponse.statusCode)")

            switch httpResponse.statusCode {
            case 201:
                do {
                    let decodedResponse = try JSONDecoder().decode(
                        SpotifyRefreshResponse.self, from: data
                    )
                    return .success(decodedResponse.accessToken)
                } catch {
                    return .failure(.decodingError(error))
                }
            case 401, 403:
                print("Refresh Error: Not Authenticated (Status \(httpResponse.statusCode))")
                return .failure(.notAuthenticated)
            case 404:
                print("Refresh Error: Refresh token not found in DB (Status 404)")
                return .failure(.notAuthenticated)
            case 500:
                print("Refresh Error: Internal Server Error (Status 500)")
                let message = try? JSONDecoder().decode(APIErrorResponse.self, from: data).error
                return .failure(
                    .apiError(statusCode: 500, message: message ?? "Internal server error"))
            default:
                print("Refresh Error: Unexpected status code \(httpResponse.statusCode)")
                let message = try? JSONDecoder().decode(APIErrorResponse.self, from: data).error
                return .failure(
                    .apiError(
                        statusCode: httpResponse.statusCode,
                        message: message ?? "Unexpected status code"
                    ))
            }

        } catch let error as URLError {
            print("Refresh Error: Network Error - \(error.localizedDescription)")
            return .failure(.networkError(error))
        } catch {
            print("Refresh Error: Unknown error - \(error.localizedDescription)")
            return .failure(.unknownError)
        }
    }
}
