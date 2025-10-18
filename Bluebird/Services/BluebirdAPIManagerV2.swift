import Foundation
import UIKit

class BluebirdAPIManagerV2: BluebirdAccountAPIService, SpotifyAPIService {
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
        #if DEV
            let environmentKey = "DEV_API_URL"
        #else
            let environmentKey = "PROD_API_URL"
        #endif

        guard let apiURLString = dict[environmentKey] as? String else {
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

    // MARK: - Helper Methods

    private func makeRequest<T: Decodable>(
        path: String,
        method: String = "GET",
        queryItems: [URLQueryItem]? = nil,
        body: Encodable? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async -> Result<T, BluebirdAPIError> {
        guard
            var components = URLComponents(
                url: apiURL,
                resolvingAgainstBaseURL: true
            )
        else {
            return .failure(.invalidEndpoint)
        }

        components.path = path
        components.queryItems = queryItems

        guard let url = components.url else {
            return .failure(.invalidEndpoint)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        // Add authorization
        guard
            let session = try? await SupabaseClientManager.shared.client.auth
            .session
        else {
            return .failure(.notAuthenticated)
        }
        request.setValue(
            "Bearer \(session.accessToken)",
            forHTTPHeaderField: "Authorization"
        )

        // Add body if present
        if let body = body {
            do {
                request.setValue(
                    "application/json",
                    forHTTPHeaderField: "Content-Type"
                )
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                return .failure(.encodingError(error))
            }
        }

        do {
            let (data, response) = try await URLSession.shared.data(
                for: request
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }

            return decodeResponse(
                data: data,
                statusCode: httpResponse.statusCode,
                decoder: decoder
            )
        } catch let error as URLError {
            return .failure(.networkError(error))
        } catch {
            return .failure(.unknownError)
        }
    }

    private func decodeResponse<T: Decodable>(
        data: Data,
        statusCode: Int,
        successCodes: Set<Int> = [200, 201],
        decoder: JSONDecoder
    ) -> Result<T, BluebirdAPIError> {
        if successCodes.contains(statusCode) {
            do {
                let decoded = try decoder.decode(T.self, from: data)
                return .success(decoded)
            } catch {
                return .failure(
                    .decodingError(statusCode: statusCode, error: error)
                )
            }
        } else {
            do {
                let errorResponse = try JSONDecoder().decode(
                    APIErrorResponse.self,
                    from: data
                )
                return .failure(
                    .apiError(
                        statusCode: statusCode,
                        message:
                        "\(errorResponse.errorCode): \(errorResponse.error)"
                    )
                )
            } catch {
                return .failure(
                    .decodingError(statusCode: statusCode, error: error)
                )
            }
        }
    }

    // MARK: - Request retry functions

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

    // MARK: - API Methods

    func userSignUp(username: String) async -> Result<Void, BluebirdAPIError> {
        struct SignUpProfile: Encodable {
            let username: String
        }

        let result: Result<SuccessResponse, BluebirdAPIError> =
            await makeRequest(
                path: "/api/edge/signup",
                method: "POST",
                body: SignUpProfile(username: username)
            )
        return result.map { _ in () }
    }

    func updateProfile(username: String?, bio: String?, avatarPath: String?)
        async -> Result<Void, BluebirdAPIError>
    {
        guard username != nil || bio != nil || avatarPath != nil else {
            fatalError("Error: at least one field must be non-nil")
        }

        let result: Result<SuccessResponse, BluebirdAPIError> =
            await makeRequest(
                path: "/api/edge/update-profile",
                method: "PATCH",
                body: UpdateProfileRequest(
                    username: username,
                    bio: bio,
                    avatarUrl: avatarPath
                )
            )
        return result.map { _ in () }
    }

    func getProfile() async -> Result<ProfileInfo, BluebirdAPIError> {
        return await makeRequest(path: "/api/me")
    }

    func getConnectedAccountDetail(accessToken: String) async -> Result<
        ConnectedAccountDetails, BluebirdAPIError
    > {
        return await makeRequest(
            path: "/api/me/connected-account-details",
            queryItems: [URLQueryItem(name: "accessToken", value: accessToken)]
        )
    }

    func getOnboardingStatus() async -> Result<OnboardingStatusResponse, BluebirdAPIError> {
        return await makeRequest(path: "/api/me/onboarding")
    }

    func completeOnboarding() async -> Result<Void, BluebirdAPIError> {
        let result: Result<SuccessResponse, BluebirdAPIError> =
            await makeRequest(path: "/api/me/onboarding", method: "PATCH")
        return result.map { _ in () }
    }

    func refreshSpotifyAccessToken() async -> Result<String, BluebirdAPIError> {
        let result: Result<SpotifyRefreshResponse, BluebirdAPIError> =
            await makeRequest(path: "/api/spotify/refresh")
        return result.map { $0.accessToken }
    }

    func saveSpotifyAccessTokenClientID(
        accessToken: String,
        refreshToken: String,
        tokenExpiry: String,
        scopes: String
    ) async -> Result<String, BluebirdAPIError> {
        let result: Result<SpotifySaveResponse, BluebirdAPIError> =
            await makeRequest(
                path: "/api/spotify/save",
                queryItems: [
                    URLQueryItem(name: "accessToken", value: accessToken),
                    URLQueryItem(name: "refreshToken", value: refreshToken),
                    URLQueryItem(name: "tokenExpiry", value: tokenExpiry),
                    URLQueryItem(name: "scopes", value: scopes),
                ]
            )
        return result.map { $0.accessToken }
    }

    // MARK: - Spotify Methods with Token Retry

    func getCurrentlyPlaying(spotifyAccessToken: String) async -> Result<
        SongDetail, BluebirdAPIError
    > {
        return await executeWithSpotifyTokenRetry(
            initialToken: spotifyAccessToken
        ) { token in
            await self._getCurrentlyPlaying(spotifyAccessToken: token)
        }
    }

    private func _getCurrentlyPlaying(spotifyAccessToken: String) async
        -> Result<SongDetail, BluebirdAPIError>
    {
        return await makeRequest(
            path: "/api/spotify/currently-playing",
            queryItems: [
                URLQueryItem(name: "accessToken", value: spotifyAccessToken),
            ]
        )
    }

    func getSongHistory(spotifyAccessToken: String) async -> Result<
        [SongDetail], BluebirdAPIError
    > {
        return await executeWithSpotifyTokenRetry(
            initialToken: spotifyAccessToken
        ) { token in
            await self._getSongHistory(spotifyAccessToken: token)
        }
    }

    private func _getSongHistory(spotifyAccessToken: String) async -> Result<
        [SongDetail], BluebirdAPIError
    > {
        return await makeRequest(
            path: "/api/spotify/refresh-song-history",
            queryItems: [
                URLQueryItem(name: "accessToken", value: spotifyAccessToken),
            ]
        )
    }

    func getArtistDetail(spotifyAccessToken: String, id: String) async
        -> Result<ArtistDetail, BluebirdAPIError>
    {
        return await executeWithSpotifyTokenRetry(
            initialToken: spotifyAccessToken
        ) { token in
            await self._getArtistDetail(spotifyAccessToken: token, id: id)
        }
    }

    private func _getArtistDetail(spotifyAccessToken: String, id: String) async
        -> Result<ArtistDetail, BluebirdAPIError>
    {
        return await makeRequest(
            path: "/api/spotify/artists/detail",
            queryItems: [
                URLQueryItem(name: "accessToken", value: spotifyAccessToken),
                URLQueryItem(name: "id", value: id),
            ]
        )
    }

    func getSongDetail(spotifyAccessToken: String, id: String) async -> Result<
        SongDetail, BluebirdAPIError
    > {
        return await executeWithSpotifyTokenRetry(
            initialToken: spotifyAccessToken
        ) { token in
            await self._getSongDetail(spotifyAccessToken: token, id: id)
        }
    }

    private func _getSongDetail(spotifyAccessToken: String, id: String) async
        -> Result<SongDetail, BluebirdAPIError>
    {
        return await makeRequest(
            path: "/api/spotify/song/detail",
            queryItems: [
                URLQueryItem(name: "accessToken", value: spotifyAccessToken),
                URLQueryItem(name: "id", value: id),
            ]
        )
    }

    func getAlbumDetail(spotifyAccessToken: String, id: String) async -> Result<
        AlbumDetail, BluebirdAPIError
    > {
        return await executeWithSpotifyTokenRetry(
            initialToken: spotifyAccessToken
        ) { token in
            await self._getAlbumDetail(spotifyAccessToken: token, id: id)
        }
    }

    private func _getAlbumDetail(spotifyAccessToken: String, id: String) async
        -> Result<AlbumDetail, BluebirdAPIError>
    {
        return await makeRequest(
            path: "/api/spotify/album/detail",
            queryItems: [
                URLQueryItem(name: "accessToken", value: spotifyAccessToken),
                URLQueryItem(name: "id", value: id),
            ]
        )
    }

    // MARK: - Stats Methods

    func getHeadlineStats(for days: Int) async -> Result<
        HeadlineViewStats, BluebirdAPIError
    > {
        return await makeRequest(
            path: "/api/me/stats",
            queryItems: [URLQueryItem(name: "days", value: String(days))]
        )
    }

    func getWeeklyPlatformComparison() async -> Result<
        WeeklyPlatformComparison, BluebirdAPIError
    > {
        return await makeRequest(path: "/api/me/weekly-platform-comparison")
    }

    func getHourlyPlays(for days: Int) async -> Result<
        [HourlyPlay], BluebirdAPIError
    > {
        return await makeRequest(
            path: "/api/me/hourly-plays",
            queryItems: [URLQueryItem(name: "days", value: String(days))]
        )
    }

    func getDailyPlays() async -> Result<[DailyPlay], BluebirdAPIError> {
        return await makeRequest(path: "/api/me/daily-plays")
    }

    func getTopArtists(for days: Int) async -> Result<
        TopArtists, BluebirdAPIError
    > {
        return await makeRequest(
            path: "/api/me/top-artists",
            queryItems: [URLQueryItem(name: "days", value: String(days))]
        )
    }

    func getTopTracks(for days: Int) async -> Result<
        TopTracks, BluebirdAPIError
    > {
        return await makeRequest(
            path: "/api/me/top-tracks",
            queryItems: [URLQueryItem(name: "days", value: String(days))]
        )
    }

    func getEntityPlays(
        for id: String,
        forDays days: Int,
        entityType: EntityType
    ) async -> Result<Int, BluebirdAPIError> {
        struct Response: Decodable {
            let plays: Int
        }

        let result: Result<Response, BluebirdAPIError> = await makeRequest(
            path: "/api/me/plays",
            queryItems: [
                URLQueryItem(name: "type", value: entityType.rawValue),
                URLQueryItem(name: "id", value: id),
                URLQueryItem(name: "days", value: String(days)),
            ]
        )
        return result.map { $0.plays }
    }

    func getTrackTrend(for id: String) async -> Result<
        TrackTrendResponse, BluebirdAPIError
    > {
        let isoDecoder = JSONDecoder()
        isoDecoder.dateDecodingStrategy = .iso8601
        return await makeRequest(
            path: "/api/me/track-trend",
            queryItems: [
                URLQueryItem(name: "type", value: "track"),
                URLQueryItem(name: "id", value: id),
            ],
            decoder: isoDecoder
        )
    }

    func getTrackLastPlayed(for id: String) async -> Result<
        Date?, BluebirdAPIError
    > {
        struct Response: Decodable {
            let last_played: Date?
        }
        let isoDecoder = JSONDecoder()
        isoDecoder.dateDecodingStrategy = .iso8601

        let result: Result<Response, BluebirdAPIError> = await makeRequest(
            path: "/api/me/track-last-played",
            queryItems: [URLQueryItem(name: "id", value: id)],
            decoder: isoDecoder
        )
        return result.map { $0.last_played }
    }

    func getTrackRank(for id: String) async -> Result<
        Int, BluebirdAPIError
    > {
        struct Response: Decodable {
            let rank: Int
        }

        let result: Result<Response, BluebirdAPIError> = await makeRequest(
            path: "/api/me/track-user-percentile",
            queryItems: [URLQueryItem(name: "id", value: id)]
        )
        return result.map { $0.rank }
    }

    func getTopGenres(numDays: Int) async -> Result<
        GenreCounts, BluebirdAPIError
    > {
        return await makeRequest(
            path: "/api/me/top-genres",
            queryItems: [URLQueryItem(name: "days", value: String(numDays))]
        )
    }

    func getDiscoveries() async -> Result<Discoveries, BluebirdAPIError> {
        return await makeRequest(path: "/api/me/discoveries")
    }

    // MARK: - Search & Pins

    func searchSongs(query: String) async -> Result<
        SearchSongResult, BluebirdAPIError
    > {
        return await makeRequest(
            path: "/api/spotify/songs/search",
            queryItems: [URLQueryItem(name: "song", value: query)]
        )
    }

    func updatePin(
        accessToken: String,
        id: String,
        entity: EntityType,
        isDelete: Bool
    ) async -> Result<Void, BluebirdAPIError> {
        struct SavePin: Encodable {
            let id: String
        }
        let path = isDelete ? "/api/me/delete-pin" : "/api/me/add-pin"

        let result: Result<SuccessResponse, BluebirdAPIError> =
            await makeRequest(
                path: path,
                method: "PUT",
                queryItems: [
                    URLQueryItem(name: "type", value: entity.rawValue),
                    URLQueryItem(name: "accessToken", value: accessToken),
                ],
                body: SavePin(id: id)
            )

        return result.map { _ in () }
    }

    func getPins(query: String) async -> Result<
        GetPinsResponse, BluebirdAPIError
    > {
        return await makeRequest(
            path: "/api/me/pins",
            queryItems: [URLQueryItem(name: "type", value: query)]
        )
    }

    func getEntityDetails(
        trackIDs: [String],
        albumIDs: [String],
        artistIDs: [String]
    ) async -> Result<GetEntityDetailsResponse, BluebirdAPIError> {
        struct Request: Encodable {
            let tracks: [String]
            let albums: [String]
            let artists: [String]
        }

        return await makeRequest(
            path: "/api/details",
            method: "POST",
            body: Request(
                tracks: trackIDs,
                albums: albumIDs,
                artists: artistIDs
            )
        )
    }

    func getSongHistoryPaginate(before: Int) async -> Result<
        [SongDetail], BluebirdAPIError
    > {
        return await makeRequest(
            path: "/api/spotify/song-history",
            queryItems: [URLQueryItem(name: "before", value: String(before))]
        )
    }

    // MARK: - Social

    func getFriendsCurrentlyPlaying() async -> Result<
        CurrentlyPlayingResponse, BluebirdAPIError
    > {
        return await makeRequest(
            path: "/api/social/currently-playing",
        )
    }

    func getUser(userID: String) async -> Result<
        UserProfileDetail, BluebirdAPIError
    > {
        return await makeRequest(
            path: "/api/social/users/profile",
            queryItems: [URLQueryItem(name: "user_id", value: userID)]
        )
    }

    func searchUsers(query: String) async -> Result<
        SearchUserResult, BluebirdAPIError
    > {
        return await makeRequest(
            path: "/api/social/users/search",
            queryItems: [URLQueryItem(name: "username", value: query)]
        )
    }

    func sendFriendRequest(to userID: String) async -> Result<
        FriendRequestResponse, BluebirdAPIError
    > {
        return await makeRequest(
            path: "/api/social/friend-request/send",
            method: "POST",
            body: SendFriendRequestBody(recipient_id: userID)
        )
    }

    func removeFriend(friend userID: String) async -> Result<
        FriendRequestResponse, BluebirdAPIError
    > {
        return await makeRequest(
            path: "/api/social/friends/remove",
            method: "POST",
            body: SendFriendRequestBody(recipient_id: userID)
        )
    }

    func respondToFriendRequest(to userID: String, accept: Bool) async
        -> Result<
            FriendRequestResponse, BluebirdAPIError
        >
    {
        return await makeRequest(
            path: "/api/social/friend-request/respond",
            method: "POST",
            body: RespondFriendRequestBody(requester_id: userID, accept: accept)
        )
    }

    /*

     */

    func createRepost(
        on entityType: EntityType,
        for entityID: String,
        caption: String
    ) async -> Result<PostCreatedResponse, BluebirdAPIError> {
        let isoDecoder = JSONDecoder()
        isoDecoder.dateDecodingStrategy = .iso8601
        return await makeRequest(
            path: "/api/social/posts",
            method: "POST",
            body: PostActionBody(
                action: "create",
                post_id: nil,
                post_type: "repost",
                entity_type: entityType.rawValue,
                entity_id: entityID,
                caption: caption
            ),
            decoder: isoDecoder
        )
    }

    func deleteRepost(postID: String) async -> Result<Void, BluebirdAPIError> {
        let result: Result<SuccessResponse, BluebirdAPIError> = await makeRequest(
            path: "/api/social/posts",
            method: "POST",
            body: PostActionBody(
                action: "delete",
                post_id: postID,
                post_type: nil,
                entity_type: nil,
                entity_id: nil,
                caption: ""
            )
        )
        return result.map { _ in () }
    }

    func getCurrentUserReposts(
        cursor: String?,
        limit: Int?
    ) async -> Result<RepostsResponse, BluebirdAPIError> {
        let isoDecoder = JSONDecoder()
        isoDecoder.dateDecodingStrategy = .iso8601

        var queryItems: [URLQueryItem] = []
        if let cursor = cursor, !cursor.isEmpty {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }

        return await makeRequest(
            path: "/api/me/reposts",
            queryItems: queryItems.isEmpty ? nil : queryItems,
            decoder: isoDecoder
        )
    }

    func getUserReposts(
        userID: String,
        cursor: String?,
        limit: Int?
    ) async -> Result<RepostsResponse, BluebirdAPIError> {
        let isoDecoder = JSONDecoder()
        isoDecoder.dateDecodingStrategy = .iso8601

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "user_id", value: userID),
        ]
        if let cursor = cursor, !cursor.isEmpty {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }

        return await makeRequest(
            path: "/api/social/users/reposts",
            queryItems: queryItems,
            decoder: isoDecoder
        )
    }

    func getFeed(
        limit: Int?,
        offset: Int?
    ) async -> Result<FeedResponse, BluebirdAPIError> {
        let isoDecoder = JSONDecoder()
        isoDecoder.dateDecodingStrategy = .iso8601

        var queryItems: [URLQueryItem] = []
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        if let offset = offset {
            queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
        }

        return await makeRequest(
            path: "/api/social/feed",
            queryItems: queryItems.isEmpty ? nil : queryItems,
            decoder: isoDecoder
        )
    }

    func getUnifiedFeed(
        limit: Int?,
        offset: Int?,
        includeHighlights: Bool = true
    ) async -> Result<UnifiedFeedResponse, BluebirdAPIError> {
        let isoDecoder = JSONDecoder()
        isoDecoder.dateDecodingStrategy = .iso8601

        var queryItems: [URLQueryItem] = []
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        if let offset = offset {
            queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
        }
        if includeHighlights {
            queryItems.append(URLQueryItem(name: "include_highlights", value: "true"))
        }

        return await makeRequest(
            path: "/api/social/feed",
            queryItems: queryItems.isEmpty ? nil : queryItems,
            decoder: isoDecoder
        )
    }

    func getLeaderboard(
        type: LeaderboardType,
        id: String,
        scope: LeaderboardScope
    ) async -> Result<LeaderboardResponse, BluebirdAPIError> {
        return await makeRequest(
            path: "/api/me/leaderboard",
            queryItems: [
                URLQueryItem(name: "type", value: type.rawValue),
                URLQueryItem(name: "id", value: id),
                URLQueryItem(name: "scope", value: scope.rawValue),
            ]
        )
    }

    func getTrendingTracks() async -> Result<[TrendingTrack], BluebirdAPIError> {
        return await makeRequest(
            path: "/api/social/trending"
        )
    }

    // MARK: - Special Cases

    @MainActor
    func initiateSpotifyConnection() async -> Result<Void, BluebirdAPIError> {
        guard
            var components = URLComponents(
                url: apiURL,
                resolvingAgainstBaseURL: true
            )
        else {
            return .failure(.invalidEndpoint)
        }

        components.path =
            apiURL.appendingPathComponent("/auth/spotify/login").path

        guard let finalURL = components.url else {
            return .failure(.invalidEndpoint)
        }

        guard UIApplication.shared.canOpenURL(finalURL) else {
            return .failure(.invalidEndpoint)
        }

        await UIApplication.shared.open(finalURL)
        return .success(())
    }
}
