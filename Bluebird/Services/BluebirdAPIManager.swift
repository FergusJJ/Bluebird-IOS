import Foundation
import UIKit

protocol BluebirdAccountAPIService {
    func userSignUp(username: String) async -> Result<Void, BluebirdAPIError>
    func initiateSpotifyConnection() async -> Result<Void, BluebirdAPIError>
    func upsertSpotifyRefreshToken(
        accessToken: String,
        refreshToken: String,
        tokenExipryString: String
    ) async -> Result<
        Void, BluebirdAPIError
    >
    func saveSpotifyAccessTokenClientID(
        accessToken: String,
        refreshToken: String,
        tokenExpiry: String
    ) async -> Result<String, BluebirdAPIError>
    func refreshSpotifyAccessToken()
        async -> Result<String, BluebirdAPIError>
    func getProfile() async -> Result<ProfileInfo, BluebirdAPIError>
    func updateProfile(username: String?, bio: String?, avatarPath: String?)
        async -> Result<Void, BluebirdAPIError>
    func getHeadlineStats() async -> Result<HeadlineViewStats, BluebirdAPIError>
    func SearchSongs(query: String) async -> Result<
        SearchSongResult, BluebirdAPIError
    >
    func updatePin(
        accessToken: String,
        id: String,
        entity: EntityType,
        isDelete: Bool
    ) async -> Result<Void, BluebirdAPIError>
    func getPins(query: String) async -> Result<
        GetPinsResponse, BluebirdAPIError
    >
    func getEntityDetails(
        trackIDs: [String],
        albumIDs: [String],
        artistIDs: [String]
    ) async -> Result<GetEntityDetailsResponse, BluebirdAPIError>
    func getHourlyPlays() async -> Result<[HourlyPlay], BluebirdAPIError>
    func getDailyPlays() async -> Result<[DailyPlay], BluebirdAPIError>
    func getTopArtists() async -> Result<TopArtists, BluebirdAPIError>
    func getTopTracks() async -> Result<TopTracks, BluebirdAPIError>
    func getEntityPlays(for id: String, entityType: EntityType) async -> Result<
        Int, BluebirdAPIError
    >
    func getTrackTrend(for id: String) async -> Result<
        TrackTrendResponse, BluebirdAPIError
    >
    func getTrackLastPlayed(for id: String) async -> Result<
        Date?, BluebirdAPIError
    >
    func getTrackUserPercentile(for id: String) async -> Result<
        Double, BluebirdAPIError
    >
    func getTopGenres(numDays: Int) async -> Result<
        GenreCounts, BluebirdAPIError
    >
}

protocol SpotifyAPIService {
    func getCurrentlyPlaying(spotifyAccessToken: String) async -> Result<
        SongDetail?, BluebirdAPIError
    >
    func getSongHistory(spotifyAccessToken: String) async -> Result<
        [SongDetail], BluebirdAPIError
    >
    func getSongHistoryPaginate(before: Int) async -> Result<
        [SongDetail], BluebirdAPIError
    >
    func getArtistDetail(spotifyAccessToken: String, id: String) async
        -> Result<
            ArtistDetail, BluebirdAPIError
        >
    func getSongDetail(spotifyAccessToken: String, id: String) async
        -> Result<
            SongDetail, BluebirdAPIError
        >
    func getAlbumDetail(spotifyAccessToken: String, id: String) async -> Result<
        AlbumDetail, BluebirdAPIError
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
    let errorCode: String
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
            return
                "Configuration Error: APICredentials.plist not found in the main bundle."
        case .invalidCredentialsFormat:
            return
                "Configuration Error: APICredentials.plist is not in a valid dictionary format."
        case .missingAPIURLKey:
            return
                "Configuration Error: The 'API_URL' key was not found in APICredentials.plist."
        case let .invalidAPIURL(urlString):
            return
                "Configuration Error: The API_URL string '\(urlString)' in APICredentials.plist is not a valid URL."
        }
    }
}

class BluebirdAPIManager: BluebirdAccountAPIService, SpotifyAPIService {
    private let apiURL: URL

    init() throws {
        guard
            let path = Bundle.main.path(
                forResource: "APICredentials",
                ofType: "plist"
            )
        else {
            throw BluebirdInitializationError.missingCredentialsPlist
        }
        guard
            let dict = NSDictionary(contentsOfFile: path)
            as? [String: AnyObject]
        else {
            throw BluebirdInitializationError.invalidCredentialsFormat
        }
        guard let apiURLString = dict["API_URL"] as? String else {
            throw BluebirdInitializationError.missingAPIURLKey
        }
        let cleanedApiURLString =
            apiURLString.hasSuffix("/")
                ? String(apiURLString.dropLast()) : apiURLString

        guard let validURL = URL(string: cleanedApiURLString) else {
            throw BluebirdInitializationError.invalidAPIURL(cleanedApiURLString)
        }
        apiURL = validURL
    }

    // MARK: - request retry functions

    private func executeWithSpotifyTokenRetry<T: Decodable>(
        initialToken: String,
        requestBuilder: @escaping (String) async -> Result<T, BluebirdAPIError>
    ) async -> Result<T, BluebirdAPIError> {
        let result = await requestBuilder(initialToken)

        if case let .failure(error) = result,
           case let .apiError(statusCode, message) = error,
           statusCode == 400,
           message?.contains("SPOTIFY_AUTH_ERROR") == true
        {
            let refreshResult = await refreshSpotifyAccessToken()

            switch refreshResult {
            case let .success(newToken):
                return await requestBuilder(newToken)
            case let .failure(refreshError):
                return .failure(refreshError)
            }
        }

        return result
    }

    func getCurrentlyPlaying(spotifyAccessToken: String) async -> Result<
        SongDetail?, BluebirdAPIError
    > {
        return await executeWithSpotifyTokenRetry(initialToken: spotifyAccessToken) { token in
            await self._getCurrentlyPlaying(spotifyAccessToken: token)
        }
    }

    func getSongHistory(spotifyAccessToken: String) async -> Result<
        [SongDetail], BluebirdAPIError
    > {
        return await executeWithSpotifyTokenRetry(initialToken: spotifyAccessToken) { token in
            await self._getSongHistory(spotifyAccessToken: token)
        }
    }

    func getArtistDetail(spotifyAccessToken: String, id: String) async -> Result<
        ArtistDetail, BluebirdAPIError
    > {
        return await executeWithSpotifyTokenRetry(initialToken: spotifyAccessToken) { token in
            await self._getArtistDetail(spotifyAccessToken: token, id: id)
        }
    }

    func getSongDetail(spotifyAccessToken: String, id: String) async -> Result<
        SongDetail, BluebirdAPIError
    > {
        return await executeWithSpotifyTokenRetry(initialToken: spotifyAccessToken) { token in
            await self._getSongDetail(spotifyAccessToken: token, id: id)
        }
    }

    func getAlbumDetail(spotifyAccessToken: String, id: String) async -> Result<
        AlbumDetail, BluebirdAPIError
    > {
        return await executeWithSpotifyTokenRetry(initialToken: spotifyAccessToken) { token in
            await self._getAlbumDetail(spotifyAccessToken: token, id: id)
        }
    }

    func userSignUp(username: String) async -> Result<Void, BluebirdAPIError> {
        guard
            var components = URLComponents(
                url: apiURL,
                resolvingAgainstBaseURL: true
            )
        else {
            return .failure(.invalidEndpoint)
        }
        components.path = "/api/edge/signup"
        guard let url = components.url else {
            return .failure(.invalidEndpoint)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        do {
            let session = try await SupabaseClientManager.shared.client.auth
                .session
            request.setValue(
                "Bearer \(session.accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        } catch {
            return .failure(.notAuthenticated)
        }
        struct SignUpProfile: Encodable {
            let username: String
        }

        let signUpProfile = SignUpProfile(username: username)
        do {
            let jsonData = try JSONEncoder().encode(signUpProfile)
            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
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
            let (data, response) = try await URLSession.shared.data(
                for: request
            )
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            switch httpResponse.statusCode {
            case 201:
                return .success(())
            default:
                do {
                    let errorResponse = try JSONDecoder().decode(
                        APIErrorResponse.self,
                        from: data
                    )
                    return .failure(
                        .apiError(
                            statusCode: httpResponse.statusCode,
                            message:
                            "\(errorResponse.errorCode): \(errorResponse.error)"
                        )
                    )
                } catch {
                    return .failure(
                        .decodingError(
                            statusCode:
                            httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            }

        } catch {
            print("Signup network request failed", "error", error)
            return .failure(.networkError(error))
        }
    }

    func updateProfile(username: String?, bio: String?, avatarPath: String?)
        async -> Result<Void, BluebirdAPIError>
    {
        // this should never happen unless i make a mistake
        print("in update profile, sending request")
        guard username != nil || bio != nil || avatarPath != nil else {
            print("Error: at least one field must be non-nil")
            fatalError()
        }
        guard
            var components = URLComponents(
                url: apiURL,
                resolvingAgainstBaseURL: true
            )
        else {
            print(
                "Error: Could not create URLComponents from base URL: \(apiURL)"
            )
            return .failure(.invalidEndpoint)
        }
        components.path =
            apiURL.appendingPathComponent("/api/edge/update-profile").path
        guard let finalURL = components.url else {
            print(
                "Error: Could not create final URL from URLComponents: \(components)"
            )
            return .failure(.invalidEndpoint)
        }
        var request = URLRequest(url: finalURL)
        request.httpMethod = "PATCH"

        if let session = try? await SupabaseClientManager.shared.client.auth
            .session
        {
            request.setValue(
                "Bearer \(session.accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        } else {
            return .failure(.notAuthenticated)
        }
        do {
            let jsonData = try JSONEncoder().encode(
                UpdateProfileRequest(
                    username: username,
                    bio: bio,
                    avatarUrl: avatarPath
                )
            )
            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
            request.httpBody = jsonData
        } catch {
            print("Error encoding JSON: \(error)")
            return .failure(.encodingError(error))
        }
        do {
            struct UpdateProfileResponse: Decodable {
                let message: String
                enum CodingKeys: String, CodingKey {
                    case message
                }
            }
            let (data, response) = try await URLSession.shared.data(
                for: request
            )
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            switch httpResponse.statusCode {
            case 200:
                do {
                    // might end up sending more info back from API
                    // so going to decode message anyways
                    _ = try JSONDecoder().decode(
                        UpdateProfileResponse.self,
                        from: data
                    )
                    return .success(())
                } catch {
                    print("Save Error: decoding error")
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            default:
                do {
                    let errorResponse = try JSONDecoder().decode(
                        APIErrorResponse.self,
                        from: data
                    )
                    return .failure(
                        .apiError(
                            statusCode: httpResponse.statusCode,
                            message:
                            "\(errorResponse.errorCode): \(errorResponse.error)"
                        )
                    )

                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            }
        } catch {
            print("Update profile network request failed", "error", error)
            return .failure(.networkError(error))
        }
    }

    /* BluebirdAccountAPIService methods */
    @MainActor
    func initiateSpotifyConnection() async -> Result<Void, BluebirdAPIError> {
        guard
            var components = URLComponents(
                url: apiURL,
                resolvingAgainstBaseURL: true
            )
        else {
            print(
                "Error: Could not create URLComponents from base URL: \(apiURL)"
            )
            return .failure(.invalidEndpoint)
        }

        components.path =
            apiURL.appendingPathComponent("/auth/spotify/login").path

        guard let finalURL = components.url else {
            print(
                "Error: Could not create final URL from URLComponents: \(components)"
            )
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
        accessToken: String,
        refreshToken: String,
        tokenExpiry: String
    ) async -> Result<String, BluebirdAPIError> {
        guard
            var components = URLComponents(
                url: apiURL,
                resolvingAgainstBaseURL: true
            )
        else {
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
        if let session = try? await SupabaseClientManager.shared.client.auth
            .session
        {
            request.setValue(
                "Bearer \(session.accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        } else {
            return .failure(.notAuthenticated)
        }
        do {
            let (data, response) = try await URLSession.shared.data(
                for: request
            )
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Save Error: Invalid response type")
                return .failure(.invalidResponse)
            }
            print("Save Token Response Status: \(httpResponse.statusCode)")
            switch httpResponse.statusCode {
            case 201:
                do {
                    let decodedResponse = try JSONDecoder().decode(
                        SpotifySaveResponse.self,
                        from: data
                    )
                    return .success(decodedResponse.accessToken)
                } catch {
                    print("Save Error: decoding error")
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            default:
                do {
                    let errorResponse = try JSONDecoder().decode(
                        APIErrorResponse.self,
                        from: data
                    )
                    return .failure(
                        .apiError(
                            statusCode: httpResponse.statusCode,
                            message:
                            "\(errorResponse.errorCode): \(errorResponse.error)"
                        )
                    )
                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            }
        } catch let error as URLError {
            print("Save Error: Network Error - \(error.localizedDescription)")
            return .failure(.networkError(error))
        } catch {
            print("Save Error: Unknown error - \(error.localizedDescription)")
            return .failure(.unknownError)
        }
    }

    func upsertSpotifyRefreshToken(
        accessToken: String,
        refreshToken: String,
        tokenExipryString: String
    ) async -> Result<
        Void, BluebirdAPIError
    > {
        guard
            var components = URLComponents(
                url: apiURL,
                resolvingAgainstBaseURL: true
            )
        else {
            return .failure(.invalidEndpoint)
        }
        components.path = "/api/spotify/data"
        guard let url = components.url else {
            return .failure(.invalidEndpoint)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        do {
            let session = try await SupabaseClientManager.shared.client.auth
                .session
            request.setValue(
                "Bearer \(session.accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        } catch {
            return .failure(.notAuthenticated)
        }

        struct UpsertRefreshToken: Encodable {
            let accessToken: String
            let refreshToken: String
            let tokenExpiry: String
            enum CodingKeys: String, CodingKey {
                case accessToken = "access_token"
                case refreshToken = "refresh_token"
                case tokenExpiry = "token_expiry"
            }
        }

        let upsertRefreshToken = UpsertRefreshToken(
            accessToken: accessToken,
            refreshToken: refreshToken,
            tokenExpiry: tokenExipryString
        )

        do {
            let jsonData = try JSONEncoder().encode(upsertRefreshToken)
            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
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
            let (data, response) = try await URLSession.shared.data(
                for: request
            )
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            switch httpResponse.statusCode {
            case 200:
                return .success(())
            default:
                do {
                    let errorResponse = try JSONDecoder().decode(
                        APIErrorResponse.self,
                        from: data
                    )
                    return .failure(
                        .apiError(
                            statusCode: httpResponse.statusCode,
                            message:
                            "\(errorResponse.errorCode): \(errorResponse.error)"
                        )
                    )

                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            }
        } catch {
            print("Signup network request failed", "error", error)
            return .failure(.networkError(error))
        }
    }

    func refreshSpotifyAccessToken() async -> Result<
        String, BluebirdAPIError
    > {
        guard
            var components = URLComponents(
                url: apiURL,
                resolvingAgainstBaseURL: true
            )
        else {
            return .failure(.invalidEndpoint)
        }
        // HandleSpotifyRefreshAuth
        let refreshPath = "/api/spotify/refresh"
        components.path = refreshPath
        guard let url = components.url else {
            return .failure(.invalidEndpoint)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        print("attempting to het api token from supabase")
        if let session = try? await SupabaseClientManager.shared.client.auth
            .session
        {
            request.setValue(
                "Bearer \(session.accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        } else {
            return .failure(.notAuthenticated)
        }

        do {
            let (data, response) = try await URLSession.shared.data(
                for: request
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Refresh Error: Invalid response type")
                return .failure(.invalidResponse)
            }

            print("Refresh Token Response Status: \(httpResponse.statusCode)")

            switch httpResponse.statusCode {
            case 201:
                do {
                    let decodedResponse = try JSONDecoder().decode(
                        SpotifyRefreshResponse.self,
                        from: data
                    )
                    return .success(decodedResponse.accessToken)
                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }

            default:
                do {
                    let errorResponse = try JSONDecoder().decode(
                        APIErrorResponse.self,
                        from: data
                    )
                    return .failure(
                        .apiError(
                            statusCode: httpResponse.statusCode,
                            message:
                            "\(errorResponse.errorCode): \(errorResponse.error)"
                        )
                    )

                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            }
        } catch let error as URLError {
            print(
                "Refresh Error: Network Error - \(error.localizedDescription)"
            )
            return .failure(.networkError(error))
        } catch {
            print(
                "Refresh Error: Unknown error - \(error.localizedDescription)"
            )
            return .failure(.unknownError)
        }
    }

    // MARK: Profile related methods

    func getProfile() async -> Result<ProfileInfo, BluebirdAPIError> {
        guard
            var components = URLComponents(
                url: apiURL,
                resolvingAgainstBaseURL: true
            )
        else {
            return .failure(.invalidEndpoint)
        }
        let profilePath = "/api/me"
        components.path = profilePath
        guard let url = components.url else {
            return .failure(.invalidEndpoint)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        print("attempting to get api token from supabase")
        if let session = try? await SupabaseClientManager.shared.client.auth
            .session
        {
            request.setValue(
                "Bearer \(session.accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        } else {
            return .failure(.notAuthenticated)
        }

        do {
            let (data, response) = try await URLSession.shared.data(
                for: request
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                print("ProfileInfo Error: Invalid response type")
                return .failure(.invalidResponse)
            }
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decodedResponse = try JSONDecoder().decode(
                        ProfileInfo.self,
                        from: data
                    )
                    return .success(decodedResponse)
                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }

            default:
                do {
                    let errorResponse = try JSONDecoder().decode(
                        APIErrorResponse.self,
                        from: data
                    )
                    return .failure(
                        .apiError(
                            statusCode: httpResponse.statusCode,
                            message:
                            "\(errorResponse.errorCode): \(errorResponse.error)"
                        )
                    )

                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            }
        } catch let error as URLError {
            print(
                "ProfileInfo Error: Network Error - \(error.localizedDescription)"
            )
            return .failure(.networkError(error))
        } catch {
            print(
                "ProfileInfo Error: Unknown error - \(error.localizedDescription)"
            )
            return .failure(.unknownError)
        }
    }

    // MARK: -  SpotifyAPIService methods

    func _getCurrentlyPlaying(spotifyAccessToken: String) async -> Result<
        SongDetail?, BluebirdAPIError
    > {
        guard
            var components = URLComponents(
                url: apiURL,
                resolvingAgainstBaseURL: true
            )
        else {
            return .failure(.invalidEndpoint)
        }
        let getCurrentlyPlayingPath = "/api/spotify/currently-playing"
        components.path = getCurrentlyPlayingPath
        let queryItems = [
            URLQueryItem(name: "accessToken", value: spotifyAccessToken),
        ]
        components.queryItems = queryItems
        guard let url = components.url
        else {
            return .failure(.invalidEndpoint)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let session = try? await SupabaseClientManager.shared.client.auth
            .session
        {
            request.setValue(
                "Bearer \(session.accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        } else {
            return .failure(.notAuthenticated)
        }

        do {
            let (data, response) = try await URLSession.shared.data(
                for: request
            )
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Refresh Error: Invalid response type")
                return .failure(.invalidResponse)
            }
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decodedResponse = try JSONDecoder().decode(
                        SongDetail.self,
                        from: data
                    )
                    return .success(decodedResponse)
                } catch {
                    print("Decoding error: \(error)")
                    if let decodingError = error as? DecodingError {
                        print("Detailed error: \(decodingError)")
                    }
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }

            case 204:
                return .success(nil)

            default:
                do {
                    let errorResponse = try JSONDecoder().decode(
                        APIErrorResponse.self,
                        from: data
                    )
                    return .failure(
                        .apiError(
                            statusCode: httpResponse.statusCode,
                            message:
                            "\(errorResponse.errorCode): \(errorResponse.error)"
                        )
                    )
                } catch {
                    print("Unknown response received from API")
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            }

        } catch let error as URLError {
            print(
                "Refresh Error: Network Error - \(error.localizedDescription)"
            )
            return .failure(.networkError(error))
        } catch {
            print(
                "Refresh Error: Unknown error - \(error.localizedDescription)"
            )
            return .failure(.unknownError)
        }
    }

    // TODO:
    func getSongHistoryPaginate(before: Int) async -> Result<
        [SongDetail], BluebirdAPIError
    > {
        guard
            var components = URLComponents(
                url: apiURL,
                resolvingAgainstBaseURL: true
            )
        else {
            return .failure(.invalidEndpoint)
        }
        print(before)
        let getSongHistoryPaginatePath = "/api/spotify/song-history"
        components.path = getSongHistoryPaginatePath
        let queryItems = [URLQueryItem(name: "before", value: String(before))]
        components.queryItems = queryItems
        guard let url = components.url
        else {
            return .failure(.invalidEndpoint)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let session = try? await SupabaseClientManager.shared.client.auth
            .session
        {
            request.setValue(
                "Bearer \(session.accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        } else {
            return .failure(.notAuthenticated)
        }
        do {
            let (data, response) = try await URLSession.shared.data(
                for: request
            )
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Refresh Error: Invalid response type")
                return .failure(.invalidResponse)
            }
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decodedResponse = try JSONDecoder().decode(
                        [SongDetail].self,
                        from: data
                    )
                    return .success(decodedResponse)
                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }

            default:
                do {
                    let errorResponse = try JSONDecoder().decode(
                        APIErrorResponse.self,
                        from: data
                    )
                    return .failure(
                        .apiError(
                            statusCode: httpResponse.statusCode,
                            message:
                            "\(errorResponse.errorCode): \(errorResponse.error)"
                        )
                    )
                } catch {
                    print("Unknown response received from API")
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            }

        } catch let error as URLError {
            print(
                "Refresh Error: Network Error - \(error.localizedDescription)"
            )
            return .failure(.networkError(error))
        } catch {
            print(
                "Refresh Error: Unknown error - \(error.localizedDescription)"
            )
            return .failure(.unknownError)
        }
    }

    func _getArtistDetail(spotifyAccessToken: String, id: String) async
        -> Result<ArtistDetail, BluebirdAPIError>
    {
        guard
            var components = URLComponents(
                url: apiURL,
                resolvingAgainstBaseURL: true
            )
        else {
            return .failure(.invalidEndpoint)
        }
        let getSongHistoryPath = "/api/spotify/artists/detail"
        components.path = getSongHistoryPath
        let queryItems = [
            URLQueryItem(name: "accessToken", value: spotifyAccessToken),
            URLQueryItem(name: "id", value: id),
        ]
        components.queryItems = queryItems
        guard let url = components.url
        else {
            return .failure(.invalidEndpoint)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let session = try? await SupabaseClientManager.shared.client.auth
            .session
        {
            request.setValue(
                "Bearer \(session.accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        } else {
            return .failure(.notAuthenticated)
        }

        do {
            let (data, response) = try await URLSession.shared.data(
                for: request
            )
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Artist Detail Error: Invalid response type")
                return .failure(.invalidResponse)
            }
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decodedResponse = try JSONDecoder().decode(
                        ArtistDetail.self,
                        from: data
                    )
                    return .success(decodedResponse)
                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }

            default:
                do {
                    let errorResponse = try JSONDecoder().decode(
                        APIErrorResponse.self,
                        from: data
                    )
                    return .failure(
                        .apiError(
                            statusCode: httpResponse.statusCode,
                            message:
                            "\(errorResponse.errorCode): \(errorResponse.error)"
                        )
                    )
                } catch {
                    print("Unknown response received from API")
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            }

        } catch let error as URLError {
            print(
                "Artist Detail Error: Network Error - \(error.localizedDescription)"
            )
            return .failure(.networkError(error))
        } catch {
            print(
                "Artist Detail Error: Unknown error - \(error.localizedDescription)"
            )
            return .failure(.unknownError)
        }
    }

    func _getSongDetail(spotifyAccessToken: String, id: String) async -> Result<
        SongDetail, BluebirdAPIError
    > {
        guard
            var components = URLComponents(
                url: apiURL,
                resolvingAgainstBaseURL: true
            )
        else {
            return .failure(.invalidEndpoint)
        }
        let getSongHistoryPath = "/api/spotify/song/detail"
        components.path = getSongHistoryPath
        let queryItems = [
            URLQueryItem(name: "accessToken", value: spotifyAccessToken),
            URLQueryItem(name: "id", value: id),
        ]
        components.queryItems = queryItems
        guard let url = components.url
        else {
            return .failure(.invalidEndpoint)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let session = try? await SupabaseClientManager.shared.client.auth
            .session
        {
            request.setValue(
                "Bearer \(session.accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        } else {
            return .failure(.notAuthenticated)
        }

        do {
            let (data, response) = try await URLSession.shared.data(
                for: request
            )
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Artist Detail Error: Invalid response type")
                return .failure(.invalidResponse)
            }
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decodedResponse = try JSONDecoder().decode(
                        SongDetail.self,
                        from: data
                    )
                    return .success(decodedResponse)
                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }

            default:
                do {
                    let errorResponse = try JSONDecoder().decode(
                        APIErrorResponse.self,
                        from: data
                    )
                    return .failure(
                        .apiError(
                            statusCode: httpResponse.statusCode,
                            message:
                            "\(errorResponse.errorCode): \(errorResponse.error)"
                        )
                    )
                } catch {
                    print("Unknown response received from API")
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            }

        } catch let error as URLError {
            print(
                "Song Detail Error: Network Error - \(error.localizedDescription)"
            )
            return .failure(.networkError(error))
        } catch {
            print(
                "Song Detail Error: Unknown error - \(error.localizedDescription)"
            )
            return .failure(.unknownError)
        }
    }

    func _getAlbumDetail(spotifyAccessToken: String, id: String) async -> Result<
        AlbumDetail, BluebirdAPIError
    > {
        guard
            var components = URLComponents(
                url: apiURL,
                resolvingAgainstBaseURL: true
            )
        else {
            return .failure(.invalidEndpoint)
        }
        let getSongHistoryPath = "/api/spotify/album/detail"
        components.path = getSongHistoryPath
        let queryItems = [
            URLQueryItem(name: "accessToken", value: spotifyAccessToken),
            URLQueryItem(name: "id", value: id),
        ]
        components.queryItems = queryItems
        guard let url = components.url
        else {
            return .failure(.invalidEndpoint)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let session = try? await SupabaseClientManager.shared.client.auth
            .session
        {
            request.setValue(
                "Bearer \(session.accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        } else {
            return .failure(.notAuthenticated)
        }

        do {
            let (data, response) = try await URLSession.shared.data(
                for: request
            )
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Artist Detail Error: Invalid response type")
                return .failure(.invalidResponse)
            }
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decodedResponse = try JSONDecoder().decode(
                        AlbumDetail.self,
                        from: data
                    )
                    return .success(decodedResponse)
                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }

            default:
                do {
                    let errorResponse = try JSONDecoder().decode(
                        APIErrorResponse.self,
                        from: data
                    )
                    return .failure(
                        .apiError(
                            statusCode: httpResponse.statusCode,
                            message:
                            "\(errorResponse.errorCode): \(errorResponse.error)"
                        )
                    )
                } catch {
                    print("Unknown response received from API")
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            }

        } catch let error as URLError {
            print(
                "Album Detail Error: Network Error - \(error.localizedDescription)"
            )
            return .failure(.networkError(error))
        } catch {
            print(
                "Album Detail Error: Unknown error - \(error.localizedDescription)"
            )
            return .failure(.unknownError)
        }
    }

    func _getSongHistory(spotifyAccessToken: String) async -> Result<
        [SongDetail], BluebirdAPIError
    > {
        guard
            var components = URLComponents(
                url: apiURL,
                resolvingAgainstBaseURL: true
            )
        else {
            return .failure(.invalidEndpoint)
        }
        let getSongHistoryPath = "/api/spotify/refresh-song-history"
        components.path = getSongHistoryPath
        let queryItems = [
            URLQueryItem(name: "accessToken", value: spotifyAccessToken),
        ]
        components.queryItems = queryItems
        guard let url = components.url
        else {
            return .failure(.invalidEndpoint)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let session = try? await SupabaseClientManager.shared.client.auth
            .session
        {
            request.setValue(
                "Bearer \(session.accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        } else {
            return .failure(.notAuthenticated)
        }

        do {
            let (data, response) = try await URLSession.shared.data(
                for: request
            )
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Refresh Error: Invalid response type")
                return .failure(.invalidResponse)
            }
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decodedResponse = try JSONDecoder().decode(
                        [SongDetail].self,
                        from: data
                    )
                    return .success(decodedResponse)
                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }

            default:
                do {
                    let errorResponse = try JSONDecoder().decode(
                        APIErrorResponse.self,
                        from: data
                    )
                    return .failure(
                        .apiError(
                            statusCode: httpResponse.statusCode,
                            message:
                            "\(errorResponse.errorCode): \(errorResponse.error)"
                        )
                    )
                } catch {
                    print("Unknown response received from API")
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            }

        } catch let error as URLError {
            print(
                "Refresh Error: Network Error - \(error.localizedDescription)"
            )
            return .failure(.networkError(error))
        } catch {
            print(
                "Refresh Error: Unknown error - \(error.localizedDescription)"
            )
            return .failure(.unknownError)
        }
    }

    func getHeadlineStats() async -> Result<HeadlineViewStats, BluebirdAPIError> {
        guard
            var components = URLComponents(
                url: apiURL,
                resolvingAgainstBaseURL: true
            )
        else {
            return .failure(.invalidEndpoint)
        }
        let profilePath = "/api/me/stats"
        components.path = profilePath
        guard let url = components.url else {
            return .failure(.invalidEndpoint)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        print("attempting to get api token from supabase")
        if let session = try? await SupabaseClientManager.shared.client.auth
            .session
        {
            request.setValue(
                "Bearer \(session.accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        } else {
            return .failure(.notAuthenticated)
        }

        do {
            let (data, response) = try await URLSession.shared.data(
                for: request
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                print("GetHeadlineStats Error: Invalid response type")
                return .failure(.invalidResponse)
            }
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decodedResponse = try JSONDecoder().decode(
                        HeadlineViewStats.self,
                        from: data
                    )
                    return .success(decodedResponse)
                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }

            default:
                do {
                    let errorResponse = try JSONDecoder().decode(
                        APIErrorResponse.self,
                        from: data
                    )
                    return .failure(
                        .apiError(
                            statusCode: httpResponse.statusCode,
                            message:
                            "\(errorResponse.errorCode): \(errorResponse.error)"
                        )
                    )

                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            }
        } catch let error as URLError {
            print(
                "GetHeadlineStats Error: Network Error - \(error.localizedDescription)"
            )
            return .failure(.networkError(error))
        } catch {
            print(
                "GetHeadlineStats Error: Unknown error - \(error.localizedDescription)"
            )
            return .failure(.unknownError)
        }
    }

    func SearchSongs(query: String) async -> Result<
        SearchSongResult, BluebirdAPIError
    > {
        guard
            var components = URLComponents(
                url: apiURL,
                resolvingAgainstBaseURL: true
            )
        else {
            return .failure(.invalidEndpoint)
        }

        let searchSongsPath = "/api/spotify/songs/search"
        let queryItems = [
            URLQueryItem(name: "song", value: query),
        ]
        components.path = searchSongsPath
        components.queryItems = queryItems

        guard let url = components.url else {
            return .failure(.invalidEndpoint)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let session = try? await SupabaseClientManager.shared.client.auth
            .session
        {
            request.setValue(
                "Bearer \(session.accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        } else {
            return .failure(.notAuthenticated)
        }

        do {
            let (data, response) = try await URLSession.shared.data(
                for: request
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                print("SearchSongs Error: Invalid response type")
                return .failure(.invalidResponse)
            }
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decodedResponse = try JSONDecoder().decode(
                        SearchSongResult.self,
                        from: data
                    )
                    return .success(decodedResponse)
                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }

            default:
                do {
                    let errorResponse = try JSONDecoder().decode(
                        APIErrorResponse.self,
                        from: data
                    )
                    return .failure(
                        .apiError(
                            statusCode: httpResponse.statusCode,
                            message:
                            "\(errorResponse.errorCode): \(errorResponse.error)"
                        )
                    )

                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            }
        } catch let error as URLError {
            print(
                "SearchSongs Error: Network Error - \(error.localizedDescription)"
            )
            return .failure(.networkError(error))
        } catch {
            print(
                "SearchSongs Error: Unknown error - \(error.localizedDescription)"
            )
            return .failure(.unknownError)
        }
    }

    // TODO: Add retry
    func updatePin(
        accessToken: String,
        id: String,
        entity: EntityType,
        isDelete: Bool
    ) async -> Result<Void, BluebirdAPIError> {
        guard
            var components = URLComponents(
                url: apiURL,
                resolvingAgainstBaseURL: true
            )
        else {
            return .failure(.invalidEndpoint)
        }

        var updatePinPath = "/api/me/add-pin"
        if isDelete {
            updatePinPath = "/api/me/delete-pin"
        }
        let queryItems = [
            URLQueryItem(name: "type", value: entity.rawValue),
            URLQueryItem(name: "accessToken", value: accessToken),
        ]
        components.path = updatePinPath
        components.queryItems = queryItems

        guard let url = components.url else {
            return .failure(.invalidEndpoint)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"

        struct SavePin: Encodable {
            let id: String
        }
        let savePinBody = SavePin(
            id: id
        )

        do {
            let jsonData = try JSONEncoder().encode(savePinBody)
            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
            request.httpBody = jsonData
        } catch {
            print("Error encoding JSON: \(error)")
            return .failure(.encodingError(error))
        }

        if let session = try? await SupabaseClientManager.shared.client.auth
            .session
        {
            request.setValue(
                "Bearer \(session.accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        } else {
            return .failure(.notAuthenticated)
        }

        do {
            let (data, response) = try await URLSession.shared.data(
                for: request
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                print("UpdatePin Error: Invalid response type")
                return .failure(.invalidResponse)
            }
            print("UpdatePin status code: \(httpResponse.statusCode)")
            switch httpResponse.statusCode {
            case 200:
                return .success(())
            default:
                do {
                    let errorResponse = try JSONDecoder().decode(
                        APIErrorResponse.self,
                        from: data
                    )
                    return .failure(
                        .apiError(
                            statusCode: httpResponse.statusCode,
                            message:
                            "\(errorResponse.errorCode): \(errorResponse.error)"
                        )
                    )

                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            }
        } catch let error as URLError {
            print(
                "UpdatePin Error: Network Error - \(error.localizedDescription)"
            )
            return .failure(.networkError(error))
        } catch {
            print(
                "UpdatePin Error: Unknown error - \(error.localizedDescription)"
            )
            return .failure(.unknownError)
        }
    }

    func getPins(query: String) async -> Result<
        GetPinsResponse, BluebirdAPIError
    > {
        guard
            var components = URLComponents(
                url: apiURL,
                resolvingAgainstBaseURL: true
            )
        else {
            return .failure(.invalidEndpoint)
        }

        let getPinsPath = "/api/me/pins"
        let queryItems = [
            URLQueryItem(name: "type", value: query),
        ]
        components.path = getPinsPath
        components.queryItems = queryItems

        guard let url = components.url else {
            return .failure(.invalidEndpoint)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let session = try? await SupabaseClientManager.shared.client.auth
            .session
        {
            request.setValue(
                "Bearer \(session.accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        } else {
            return .failure(.notAuthenticated)
        }

        do {
            let (data, response) = try await URLSession.shared.data(
                for: request
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                print("SearchSongs Error: Invalid response type")
                return .failure(.invalidResponse)
            }
            switch httpResponse.statusCode {
            case 200:
                do {
                    let pins = try JSONDecoder().decode(
                        GetPinsResponse.self,
                        from: data
                    )
                    return .success(pins)
                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            default:
                do {
                    let errorResponse = try JSONDecoder().decode(
                        APIErrorResponse.self,
                        from: data
                    )
                    return .failure(
                        .apiError(
                            statusCode: httpResponse.statusCode,
                            message:
                            "\(errorResponse.errorCode): \(errorResponse.error)"
                        )
                    )
                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            }
        } catch let error as URLError {
            print(
                "UpdatePin Error: Network Error - \(error.localizedDescription)"
            )
            return .failure(.networkError(error))
        } catch {
            print(
                "UpdatePin Error: Unknown error - \(error.localizedDescription)"
            )
            return .failure(.unknownError)
        }
    }

    func getEntityDetails(
        trackIDs: [String],
        albumIDs: [String],
        artistIDs: [String]
    ) async -> Result<GetEntityDetailsResponse, BluebirdAPIError> {
        guard
            var components = URLComponents(
                url: apiURL,
                resolvingAgainstBaseURL: true
            )
        else {
            return .failure(.invalidEndpoint)
        }

        let entityDetailPath = "/api/details"
        components.path = entityDetailPath

        guard let url = components.url else {
            return .failure(.invalidEndpoint)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        struct GetEntityDetailsRequest: Encodable {
            let tracks: [String]
            let albums: [String]
            let artists: [String]
        }

        let getEntityDetailsBody = GetEntityDetailsRequest(
            tracks: trackIDs,
            albums: albumIDs,
            artists: artistIDs
        )

        do {
            let jsonData = try JSONEncoder().encode(getEntityDetailsBody)
            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
            request.httpBody = jsonData
        } catch {
            print("Error encoding JSON: \(error)")
            return .failure(.encodingError(error))
        }

        if let session = try? await SupabaseClientManager.shared.client.auth
            .session
        {
            request.setValue(
                "Bearer \(session.accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        } else {
            return .failure(.notAuthenticated)
        }

        do {
            let (data, response) = try await URLSession.shared.data(
                for: request
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                print("GetEntityDetails Error: Invalid response type")
                return .failure(.invalidResponse)
            }
            switch httpResponse.statusCode {
            case 200:
                do {
                    let response = try JSONDecoder().decode(
                        GetEntityDetailsResponse.self,
                        from: data
                    )
                    return .success(response)
                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            default:
                do {
                    let errorResponse = try JSONDecoder().decode(
                        APIErrorResponse.self,
                        from: data
                    )
                    return .failure(
                        .apiError(
                            statusCode: httpResponse.statusCode,
                            message:
                            "\(errorResponse.errorCode): \(errorResponse.error)"
                        )
                    )

                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            }
        } catch let error as URLError {
            print(
                "GetEntityDetails Error: Network Error - \(error.localizedDescription)"
            )
            return .failure(.networkError(error))
        } catch {
            print(
                "GetEntityDetails Error: Unknown error - \(error.localizedDescription)"
            )
            return .failure(.unknownError)
        }
    }

    func getHourlyPlays() async -> Result<[HourlyPlay], BluebirdAPIError> {
        guard
            var components = URLComponents(
                url: apiURL,
                resolvingAgainstBaseURL: true
            )
        else {
            return .failure(.invalidEndpoint)
        }

        let hourlyPlaysPath = "/api/me/hourly-plays"
        components.path = hourlyPlaysPath

        guard let url = components.url else {
            return .failure(.invalidEndpoint)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let session = try? await SupabaseClientManager.shared.client.auth
            .session
        {
            request.setValue(
                "Bearer \(session.accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        } else {
            return .failure(.notAuthenticated)
        }

        do {
            let (data, response) = try await URLSession.shared.data(
                for: request
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                print("GetHourlyPlays Error: Invalid response type")
                return .failure(.invalidResponse)
            }
            switch httpResponse.statusCode {
            case 200:
                do {
                    let hourlyPlays = try JSONDecoder().decode(
                        [HourlyPlay].self,
                        from: data
                    )
                    return .success(hourlyPlays)
                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            default:
                do {
                    let errorResponse = try JSONDecoder().decode(
                        APIErrorResponse.self,
                        from: data
                    )
                    return .failure(
                        .apiError(
                            statusCode: httpResponse.statusCode,
                            message:
                            "\(errorResponse.errorCode): \(errorResponse.error)"
                        )
                    )
                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            }
        } catch let error as URLError {
            print(
                "GetHourlyPlays Error: Network Error - \(error.localizedDescription)"
            )
            return .failure(.networkError(error))
        } catch {
            print(
                "GetHourlyPlays Error: Unknown error - \(error.localizedDescription)"
            )
            return .failure(.unknownError)
        }
    }

    func getDailyPlays() async -> Result<[DailyPlay], BluebirdAPIError> {
        guard
            var components = URLComponents(
                url: apiURL,
                resolvingAgainstBaseURL: true
            )
        else {
            return .failure(.invalidEndpoint)
        }

        let hourlyPlaysPath = "/api/me/daily-plays"
        components.path = hourlyPlaysPath

        guard let url = components.url else {
            return .failure(.invalidEndpoint)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let session = try? await SupabaseClientManager.shared.client.auth
            .session
        {
            request.setValue(
                "Bearer \(session.accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        } else {
            return .failure(.notAuthenticated)
        }

        do {
            let (data, response) = try await URLSession.shared.data(
                for: request
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                print("GetDailyPlays Error: Invalid response type")
                return .failure(.invalidResponse)
            }
            switch httpResponse.statusCode {
            case 200:
                do {
                    let dailyPlays = try JSONDecoder().decode(
                        [DailyPlay].self,
                        from: data
                    )
                    return .success(dailyPlays)
                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            default:
                do {
                    let errorResponse = try JSONDecoder().decode(
                        APIErrorResponse.self,
                        from: data
                    )
                    return .failure(
                        .apiError(
                            statusCode: httpResponse.statusCode,
                            message:
                            "\(errorResponse.errorCode): \(errorResponse.error)"
                        )
                    )
                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            }
        } catch let error as URLError {
            print(
                "GetDailyPlays Error: Network Error - \(error.localizedDescription)"
            )
            return .failure(.networkError(error))
        } catch {
            print(
                "GetDailyPlays Error: Unknown error - \(error.localizedDescription)"
            )
            return .failure(.unknownError)
        }
    }

    func getTopArtists() async -> Result<TopArtists, BluebirdAPIError> {
        guard
            var components = URLComponents(
                url: apiURL,
                resolvingAgainstBaseURL: true
            )
        else {
            return .failure(.invalidEndpoint)
        }

        let topArtistsPath = "/api/me/top-artists"
        components.path = topArtistsPath

        guard let url = components.url else {
            return .failure(.invalidEndpoint)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let session = try? await SupabaseClientManager.shared.client.auth
            .session
        {
            request.setValue(
                "Bearer \(session.accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        } else {
            return .failure(.notAuthenticated)
        }

        do {
            let (data, response) = try await URLSession.shared.data(
                for: request
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                print("GetTopArtists Error: Invalid response type")
                return .failure(.invalidResponse)
            }
            switch httpResponse.statusCode {
            case 200:
                do {
                    let topArtists = try JSONDecoder().decode(
                        TopArtists.self,
                        from: data
                    )
                    return .success(topArtists)
                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            default:
                do {
                    let errorResponse = try JSONDecoder().decode(
                        APIErrorResponse.self,
                        from: data
                    )
                    return .failure(
                        .apiError(
                            statusCode: httpResponse.statusCode,
                            message:
                            "\(errorResponse.errorCode): \(errorResponse.error)"
                        )
                    )
                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            }
        } catch let error as URLError {
            print(
                "GetTopArtists Error: Network Error - \(error.localizedDescription)"
            )
            return .failure(.networkError(error))
        } catch {
            print(
                "GetTopArtists Error: Unknown error - \(error.localizedDescription)"
            )
            return .failure(.unknownError)
        }
    }

    func getTopTracks() async -> Result<TopTracks, BluebirdAPIError> {
        guard
            var components = URLComponents(
                url: apiURL,
                resolvingAgainstBaseURL: true
            )
        else {
            return .failure(.invalidEndpoint)
        }

        let topTracksPath = "/api/me/top-tracks"
        components.path = topTracksPath

        guard let url = components.url else {
            return .failure(.invalidEndpoint)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let session = try? await SupabaseClientManager.shared.client.auth
            .session
        {
            request.setValue(
                "Bearer \(session.accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        } else {
            return .failure(.notAuthenticated)
        }

        do {
            let (data, response) = try await URLSession.shared.data(
                for: request
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                print("GetTopTracks Error: Invalid response type")
                return .failure(.invalidResponse)
            }
            switch httpResponse.statusCode {
            case 200:
                do {
                    let topTracks = try JSONDecoder().decode(
                        TopTracks.self,
                        from: data
                    )
                    return .success(topTracks)
                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            default:
                do {
                    let errorResponse = try JSONDecoder().decode(
                        APIErrorResponse.self,
                        from: data
                    )
                    return .failure(
                        .apiError(
                            statusCode: httpResponse.statusCode,
                            message:
                            "\(errorResponse.errorCode): \(errorResponse.error)"
                        )
                    )
                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            }
        } catch let error as URLError {
            print(
                "GetTopTracks Error: Network Error - \(error.localizedDescription)"
            )
            return .failure(.networkError(error))
        } catch {
            print(
                "GetTopTracks Error: Unknown error - \(error.localizedDescription)"
            )
            return .failure(.unknownError)
        }
    }

    func getEntityPlays(for id: String, entityType: EntityType) async -> Result<
        Int, BluebirdAPIError
    > {
        guard
            var components = URLComponents(
                url: apiURL,
                resolvingAgainstBaseURL: true
            )
        else {
            return .failure(.invalidEndpoint)
        }
        let getEntityPlaysPath = "/api/me/plays"
        components.path = getEntityPlaysPath
        let queryItems = [
            URLQueryItem(name: "type", value: entityType.rawValue),
            URLQueryItem(name: "id", value: id),
        ]
        components.queryItems = queryItems
        guard let url = components.url
        else {
            return .failure(.invalidEndpoint)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let session = try? await SupabaseClientManager.shared.client.auth
            .session
        {
            request.setValue(
                "Bearer \(session.accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        } else {
            return .failure(.notAuthenticated)
        }

        do {
            let (data, response) = try await URLSession.shared.data(
                for: request
            )
            guard let httpResponse = response as? HTTPURLResponse else {
                print("GetEntityPlays Error: Invalid response type")
                return .failure(.invalidResponse)
            }
            switch httpResponse.statusCode {
            case 200:
                do {
                    struct getEntityPlaysResponse: Decodable {
                        let plays: Int
                    }
                    let decodedResponse = try JSONDecoder().decode(
                        getEntityPlaysResponse.self,
                        from: data
                    )
                    return .success(decodedResponse.plays)
                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }

            default:
                do {
                    let errorResponse = try JSONDecoder().decode(
                        APIErrorResponse.self,
                        from: data
                    )
                    return .failure(
                        .apiError(
                            statusCode: httpResponse.statusCode,
                            message:
                            "\(errorResponse.errorCode): \(errorResponse.error)"
                        )
                    )
                } catch {
                    print("Unknown response received from API")
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            }

        } catch let error as URLError {
            print(
                "GetEntityPlays Error: Network Error - \(error.localizedDescription)"
            )
            return .failure(.networkError(error))
        } catch {
            print(
                "GetEntityPlays Error: Unknown error - \(error.localizedDescription)"
            )
            return .failure(.unknownError)
        }
    }

    func getTrackTrend(for id: String) async -> Result<
        TrackTrendResponse, BluebirdAPIError
    > {
        guard
            var components = URLComponents(
                url: apiURL,
                resolvingAgainstBaseURL: true
            )
        else {
            return .failure(.invalidEndpoint)
        }
        let getEntityPlaysPath = "/api/me/track-trend"
        components.path = getEntityPlaysPath
        let queryItems = [
            URLQueryItem(name: "type", value: "track"), // specifically a track func so just hardcode
            URLQueryItem(name: "id", value: id),
        ]
        components.queryItems = queryItems
        guard let url = components.url
        else {
            return .failure(.invalidEndpoint)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let session = try? await SupabaseClientManager.shared.client.auth
            .session
        {
            request.setValue(
                "Bearer \(session.accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        } else {
            return .failure(.notAuthenticated)
        }

        do {
            let (data, response) = try await URLSession.shared.data(
                for: request
            )
            guard let httpResponse = response as? HTTPURLResponse else {
                print("GetTrackTrend Error: Invalid response type")
                return .failure(.invalidResponse)
            }
            switch httpResponse.statusCode {
            case 200:
                do {
                    let str = String(decoding: data, as: UTF8.self)
                    print(str)
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let decodedResponse = try decoder.decode(
                        TrackTrendResponse.self,
                        from: data
                    )
                    return .success(decodedResponse)
                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }

            default:
                do {
                    let errorResponse = try JSONDecoder().decode(
                        APIErrorResponse.self,
                        from: data
                    )
                    return .failure(
                        .apiError(
                            statusCode: httpResponse.statusCode,
                            message:
                            "\(errorResponse.errorCode): \(errorResponse.error)"
                        )
                    )
                } catch {
                    print("Unknown response received from API")
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            }

        } catch let error as URLError {
            print(
                "GetTrackTrend Error: Network Error - \(error.localizedDescription)"
            )
            return .failure(.networkError(error))
        } catch {
            print(
                "GetTrackTrend Error: Unknown error - \(error.localizedDescription)"
            )
            return .failure(.unknownError)
        }
    }

    func getTrackLastPlayed(for id: String) async -> Result<
        Date?, BluebirdAPIError
    > {
        guard
            var components = URLComponents(
                url: apiURL,
                resolvingAgainstBaseURL: true
            )
        else {
            return .failure(.invalidEndpoint)
        }
        let getTrackLastPlayedPath = "/api/me/track-last-played"
        components.path = getTrackLastPlayedPath
        let queryItems = [
            URLQueryItem(name: "id", value: id),
        ]
        components.queryItems = queryItems
        guard let url = components.url
        else {
            return .failure(.invalidEndpoint)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let session = try? await SupabaseClientManager.shared.client.auth
            .session
        {
            request.setValue(
                "Bearer \(session.accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        } else {
            return .failure(.notAuthenticated)
        }

        do {
            let (data, response) = try await URLSession.shared.data(
                for: request
            )
            guard let httpResponse = response as? HTTPURLResponse else {
                print("GetTrackLastPlayed Error: Invalid response type")
                return .failure(.invalidResponse)
            }
            switch httpResponse.statusCode {
            case 200:
                do {
                    guard !data.isEmpty else {
                        return .success(nil)
                    }
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let decodedResponse = try decoder.decode(
                        TrackLastPlayedResponse.self,
                        from: data
                    )
                    return .success(decodedResponse.last_played)
                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }

            default:
                do {
                    let errorResponse = try JSONDecoder().decode(
                        APIErrorResponse.self,
                        from: data
                    )
                    return .failure(
                        .apiError(
                            statusCode: httpResponse.statusCode,
                            message:
                            "\(errorResponse.errorCode): \(errorResponse.error)"
                        )
                    )
                } catch {
                    print("Unknown response received from API")
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            }

        } catch let error as URLError {
            print(
                "GetTrackLastPlayed Error: Network Error - \(error.localizedDescription)"
            )
            return .failure(.networkError(error))
        } catch {
            print(
                "GetTrackLastPlayed Error: Unknown error - \(error.localizedDescription)"
            )
            return .failure(.unknownError)
        }
    }

    func getTrackUserPercentile(for id: String) async -> Result<
        Double, BluebirdAPIError
    > {
        guard
            var components = URLComponents(
                url: apiURL,
                resolvingAgainstBaseURL: true
            )
        else {
            return .failure(.invalidEndpoint)
        }
        let getTrackLastPlayedPath = "/api/me/track-user-percentile"
        components.path = getTrackLastPlayedPath
        let queryItems = [
            URLQueryItem(name: "id", value: id),
        ]
        components.queryItems = queryItems
        guard let url = components.url
        else {
            return .failure(.invalidEndpoint)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let session = try? await SupabaseClientManager.shared.client.auth
            .session
        {
            request.setValue(
                "Bearer \(session.accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        } else {
            return .failure(.notAuthenticated)
        }

        do {
            let (data, response) = try await URLSession.shared.data(
                for: request
            )
            guard let httpResponse = response as? HTTPURLResponse else {
                print("GetTrackUserPercentile Error: Invalid response type")
                return .failure(.invalidResponse)
            }
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decodedResponse = try JSONDecoder().decode(
                        TrackUserPercentile.self,
                        from: data
                    )
                    return .success(decodedResponse.percentile)
                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }

            default:
                do {
                    let errorResponse = try JSONDecoder().decode(
                        APIErrorResponse.self,
                        from: data
                    )
                    return .failure(
                        .apiError(
                            statusCode: httpResponse.statusCode,
                            message:
                            "\(errorResponse.errorCode): \(errorResponse.error)"
                        )
                    )
                } catch {
                    print("Unknown response received from API")
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            }

        } catch let error as URLError {
            print(
                "GetTrackUserPercentile Error: Network Error - \(error.localizedDescription)"
            )
            return .failure(.networkError(error))
        } catch {
            print(
                "GetTrackUserPercentile Error: Unknown error - \(error.localizedDescription)"
            )
            return .failure(.unknownError)
        }
    }

    func getTopGenres(numDays: Int) async -> Result<
        GenreCounts, BluebirdAPIError
    > {
        guard
            var components = URLComponents(
                url: apiURL,
                resolvingAgainstBaseURL: true
            )
        else {
            return .failure(.invalidEndpoint)
        }
        let getTrackLastPlayedPath = "/api/me/top-genres"
        components.path = getTrackLastPlayedPath
        let queryItems = [
            URLQueryItem(name: "days", value: String(numDays)),
        ]
        components.queryItems = queryItems
        guard let url = components.url
        else {
            return .failure(.invalidEndpoint)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let session = try? await SupabaseClientManager.shared.client.auth
            .session
        {
            request.setValue(
                "Bearer \(session.accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        } else {
            return .failure(.notAuthenticated)
        }

        do {
            let (data, response) = try await URLSession.shared.data(
                for: request
            )
            guard let httpResponse = response as? HTTPURLResponse else {
                print("GetTopGenres Error: Invalid response type")
                return .failure(.invalidResponse)
            }
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decodedResponse = try JSONDecoder().decode(
                        GenreCounts.self,
                        from: data
                    )
                    return .success(decodedResponse)
                } catch {
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }

            default:
                do {
                    let errorResponse = try JSONDecoder().decode(
                        APIErrorResponse.self,
                        from: data
                    )
                    return .failure(
                        .apiError(
                            statusCode: httpResponse.statusCode,
                            message:
                            "\(errorResponse.errorCode): \(errorResponse.error)"
                        )
                    )
                } catch {
                    print("Unknown response received from API")
                    return .failure(
                        .decodingError(
                            statusCode: httpResponse.statusCode,
                            error: error
                        )
                    )
                }
            }

        } catch let error as URLError {
            print(
                "GetTopGenres Error: Network Error - \(error.localizedDescription)"
            )
            return .failure(.networkError(error))
        } catch {
            print(
                "GetTopGenres Error: Unknown error - \(error.localizedDescription)"
            )
            return .failure(.unknownError)
        }
    }
}
