import Foundation
import UIKit

protocol BluebirdAuthAPIService {
    func userSignUp(username: String) async -> Result<Void, BluebirdAPIError>
    func initiateSpotifyConnection() async -> Result<Void, BluebirdAPIError>
    func upsertSpotifyRefreshToken(refreshToken: String, tokenExipryString: String) async -> Result<
        Void, BluebirdAPIError
    >
    func saveSpotifyAccessTokenClientID(
        accessToken: String, refreshToken: String, tokenExpiry: String
    ) async -> Result<String, BluebirdAPIError>
    func refreshSpotifyAccessToken()
        async -> Result<String, BluebirdAPIError>
}

protocol SpotifyAPIService {
    func getCurrentlyPlaying(spotifyAccessToken: String) async -> Result<
        CurrentlyPlayingSongResponse?, BluebirdAPIError
    >
}

struct SpotifySaveResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: String
    let spotifyClientID: String
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case spotifyClientID = "spotify_client_id"
    }
}

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
    case encodingError(Error)
    case apiError(statusCode: Int, message: String?)
    case notAuthenticated
    case notFound
    case spotifyAPIError
    case unknownError

    // signUp can now print a BluebirdAPIError so need descriptions

    var errorDescription: String? {
        switch self {
        case let .networkError(error):
            if let urlError = error as? URLError {
                return "Network connection problem: \(urlError.localizedDescription)"
            }
            return "A network error occurred: \(error.localizedDescription)"
        case .invalidEndpoint:
            return "The API endpoint is misconfigured. Please contact support."
        case let .decodingError(error):
            return "Failed to process server response: \(error.localizedDescription)"
        case let .encodingError(error):
            return "Failed to prepare request data: \(error.localizedDescription)"
        case let .apiError(statusCode, message):
            let baseMessage = "Server responded with an error (\(statusCode))."
            return message != nil ? "\(baseMessage) Details: \(message!)" : baseMessage
        case .notAuthenticated:
            return "You are not authenticated. Please log in again."
        case .notFound:
            return "The requested resource was not found."
        case .spotifyAPIError:
            return "An error occurred with the Spotify API integration."
        case .unknownError:
            return "An unexpected error occurred. Please try again."
        }
    }
}

class BluebirdAPIManager: BluebirdAuthAPIService, SpotifyAPIService {
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

    func userSignUp(username: String) async -> Result<Void, BluebirdAPIError> {
        guard var components = URLComponents(url: apiURL, resolvingAgainstBaseURL: true) else {
            return .failure(.invalidEndpoint)
        }
        components.path = "/api/edge/signup"
        guard let url = components.url else {
            return .failure(.invalidEndpoint)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        do {
            let session = try await SupabaseClientManager.shared.client.auth.session
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        } catch {
            return .failure(.notAuthenticated)
        }
        struct SignUpProfile: Encodable {
            let username: String
        }

        let signUpProfile = SignUpProfile(username: username)
        do {
            let jsonData = try JSONEncoder().encode(signUpProfile)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
        } catch {
            print("Error encoding JSON: \(error)")
            return .failure(.encodingError(error))
        }
        do {
            struct SignUpResponse: Decodable {
                let message: String
                let userId: String
                let username: String

                enum CodingKeys: String, CodingKey {
                    case message
                    case userId = "user_id"
                    case username
                }
            }
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.unknownError)
            }
            switch httpResponse.statusCode {
            case 201:
                // let decodedResponse = try JSONDecoder().decode(SignUpResponse.self, from: data)
                return .success(())
            case 400, 500:
                do {
                    let decodedResponse = try JSONDecoder().decode(
                        APIErrorResponse.self, from: data
                    )
                    return .failure(
                        .apiError(
                            statusCode: httpResponse.statusCode, message: decodedResponse.error
                        ))
                } catch {
                    print("Error decoding JSON response: \(error)")
                    return .failure(.decodingError(error))
                }
            case 401:
                return .failure(.notAuthenticated)
            case 404:
                return .failure(.notFound)
            default:
                return .failure(
                    .apiError(
                        statusCode: httpResponse.statusCode,
                        message: "An unexpected error occurred."
                    ))
            }

        } catch {
            print("Signup network request failed", "error", error)
            return .failure(.networkError(error))
        }
    }

    /* BluebirdAuthAPIService methods */
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

    func saveSpotifyAccessTokenClientID(
        accessToken: String, refreshToken: String, tokenExpiry: String
    ) async -> Result<String, BluebirdAPIError> {
        guard var components = URLComponents(url: apiURL, resolvingAgainstBaseURL: true) else {
            return .failure(.invalidEndpoint)
        }
        let savePath = "/api/spotify/save"
        components.path = savePath
        let queryItems = [
            URLQueryItem(name: "accessToken", value: accessToken),
            URLQueryItem(name: "refreshToken", value: refreshToken),
            URLQueryItem(name: "tokenExpiry", value: tokenExpiry),
        ]
        components.queryItems = queryItems
        guard let url = components.url else {
            return .failure(.invalidEndpoint)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        print("attempting to get api token from supabase")
        if let session = try? await SupabaseClientManager.shared.client.auth.session {
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            return .failure(.notAuthenticated)
        }
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Save Error: Invalid response type")
                return .failure(.notAuthenticated)
            }
            print("Save Token Response Status: \(httpResponse.statusCode)")
            switch httpResponse.statusCode {
            case 201:
                do {
                    let decodedResponse = try JSONDecoder().decode(
                        SpotifySaveResponse.self, from: data
                    )
                    return .success(decodedResponse.accessToken)
                } catch {
                    print("Save Error: decoding error")
                    return .failure(.decodingError(error))
                }
            case 401, 403:
                print("Refresh Error: Not Authenticated (Status \(httpResponse.statusCode))")
                return .failure(.notAuthenticated)
            case 400:
                print("Save Error: Missing query params")
                return .failure(
                    .apiError(
                        statusCode: 400,
                        message: "Access Token, Refresh Token, Expiry not present in query params."
                    )
                )
            case 500:
                print("Save Error: Internal Server Error (Status 500)")
                let message = try? JSONDecoder().decode(APIErrorResponse.self, from: data).error
                return .failure(
                    .apiError(statusCode: 500, message: message ?? "Internal server error"))
            case 503:
                print("Save Error: Spotify API not available")
                return .failure(.spotifyAPIError)
            default:
                print("Save Error: Unexpected status code \(httpResponse.statusCode)")
                return .failure(.unknownError)
            }
        } catch let error as URLError {
            print("Save Error: Network Error - \(error.localizedDescription)")
            return .failure(.networkError(error))
        } catch {
            print("Save Error: Unknown error - \(error.localizedDescription)")
            return .failure(.unknownError)
        }
    }

    func upsertSpotifyRefreshToken(refreshToken: String, tokenExipryString: String) async -> Result<
        Void, BluebirdAPIError
    > {
        guard var components = URLComponents(url: apiURL, resolvingAgainstBaseURL: true) else {
            return .failure(.invalidEndpoint)
        }
        components.path = "/api/spotify/refresh"
        guard let url = components.url else {
            return .failure(.invalidEndpoint)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        do {
            let session = try await SupabaseClientManager.shared.client.auth.session
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        } catch {
            return .failure(.notAuthenticated)
        }

        struct UpsertRefreshToken: Encodable {
            let refreshToken: String
            let tokenExpiry: String
            enum CodingKeys: String, CodingKey {
                case refreshToken = "refresh_token"
                case tokenExpiry = "token_expiry"
            }
        }

        let upsertRefreshToken = UpsertRefreshToken(
            refreshToken: refreshToken, tokenExpiry: tokenExipryString
        )

        do {
            let jsonData = try JSONEncoder().encode(upsertRefreshToken)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
        } catch {
            print("Error encoding JSON: \(error)")
            return .failure(.encodingError(error))
        }
        do {
            struct UpsertRefreshTokenResponse: Decodable {
                let message: String
                let userId: String

                enum CodingKeys: String, CodingKey {
                    case message
                    case userId = "user_id"
                }
            }
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.unknownError)
            }
            switch httpResponse.statusCode {
            case 200:
                return .success(())
            case 400, 500:
                do {
                    let decodedResponse = try JSONDecoder().decode(
                        APIErrorResponse.self, from: data
                    )
                    return .failure(
                        .apiError(
                            statusCode: httpResponse.statusCode, message: decodedResponse.error
                        ))
                } catch {
                    print("Error decoding JSON response:  \(error)")
                    return .failure(.decodingError(error))
                }
            case 401:
                return .failure(.notAuthenticated)
            case 404:
                return .failure(.notFound)
            default:
                return .failure(
                    .apiError(
                        statusCode: httpResponse.statusCode,
                        message: "An unexpected error occurred."
                    ))
            }

        } catch {
            print("Signup network request failed", "error", error)
            return .failure(.networkError(error))
        }
    }

    func refreshSpotifyAccessToken() async -> Result<
        String, BluebirdAPIError
    > {
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
                return .failure(.notFound)
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

    /*  SpotifyAPIService methods */
    func getCurrentlyPlaying(spotifyAccessToken: String) async -> Result<
        CurrentlyPlayingSongResponse?, BluebirdAPIError
    > {
        guard var components = URLComponents(url: apiURL, resolvingAgainstBaseURL: true) else {
            return .failure(.invalidEndpoint)
        }
        let getCurrentlyPlayingPath = "/api/spotify/currently-playing"
        components.path = getCurrentlyPlayingPath
        let queryItems = [URLQueryItem(name: "accessToken", value: spotifyAccessToken)]
        components.queryItems = queryItems
        guard let url = components.url
        else {
            return .failure(.invalidEndpoint)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
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
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decodedResponse = try JSONDecoder().decode(
                        CurrentlyPlayingSongResponse.self, from: data
                    )
                    return .success(decodedResponse)
                } catch {
                    return .failure(.decodingError(error))
                }

            case 404:
                return .success(nil)

            case 400:
                return .failure(.apiError(statusCode: 400, message: "no spotify access token"))

            case 401:
                return .failure(.notAuthenticated)

            case 500:
                // api failed, nothing to do with client
                return .failure(.apiError(statusCode: 500, message: "Internal Server Error."))

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
