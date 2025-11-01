import Foundation

protocol BluebirdAccountAPIService {
    func userSignUp(username: String) async -> Result<Void, BluebirdAPIError>
    func initiateSpotifyConnection() async -> Result<Void, BluebirdAPIError>
    func saveSpotifyAccessTokenClientID(
        accessToken: String,
        refreshToken: String,
        tokenExpiry: String,
        scopes: String
    ) async -> Result<String, BluebirdAPIError>
    func refreshSpotifyAccessToken()
        async -> Result<String, BluebirdAPIError>

    // MARK: - Profile only routes

    func getProfile() async -> Result<ProfileInfo, BluebirdAPIError>
    func updateProfile(
        username: String?,
        bio: String?,
        avatarPath: String?,
        profileVisibility: String?
    ) async -> Result<Void, BluebirdAPIError>
    func getHeadlineStats(for days: Int) async -> Result<
        HeadlineViewStats, BluebirdAPIError
    >
    func getConnectedAccountDetail(accessToken: String) async -> Result<
        ConnectedAccountDetails, BluebirdAPIError
    >
    func getOnboardingStatus() async -> Result<OnboardingStatusResponse, BluebirdAPIError>
    func completeOnboarding() async -> Result<Void, BluebirdAPIError>

    // MARK: - Songs routes

    func searchSongs(query: String) async -> Result<
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
    func getHourlyPlaysMinutes() async -> Result<
            [HourlyPlay], BluebirdAPIError
    >
    func getHourlyPlays(for days: Int) async -> Result<
        [HourlyPlay], BluebirdAPIError
    >
    func getDailyPlays() async -> Result<[DailyPlay], BluebirdAPIError>
    func getTopArtists(for days: Int) async -> Result<
        TopArtists, BluebirdAPIError
    >
    func getTopTracks(for days: Int) async -> Result<
        TopTracks, BluebirdAPIError
    >
    func getEntityPlays(
        for id: String,
        forDays days: Int,
        entityType: EntityType
    ) async -> Result<
        Int, BluebirdAPIError
    >
    func getTrackTrend(for id: String) async -> Result<
        TrackTrendResponse, BluebirdAPIError
    >
    func getTrackLastPlayed(for id: String) async -> Result<
        Date?, BluebirdAPIError
    >
    func getTrackRank(for id: String) async -> Result<
        Int, BluebirdAPIError
    >
    func getWeeklyPlatformComparison() async -> Result<
        WeeklyPlatformComparison, BluebirdAPIError
    >
    func getTopGenres(numDays: Int) async -> Result<
        GenreCounts, BluebirdAPIError
    >
    func getDiscoveries() async -> Result<Discoveries, BluebirdAPIError>

    // MARK: - social routes

    func searchUsers(query: String) async -> Result<
        SearchUserResult, BluebirdAPIError
    >

    func getFriendsCurrentlyPlaying() async -> Result<
        CurrentlyPlayingResponse, BluebirdAPIError
    >
    func getUser(userID: String) async -> Result<
        UserProfileDetail, BluebirdAPIError
    >
    func getAllFriends(for userID: String) async -> Result<
        [UserProfile], BluebirdAPIError
    >
    func getPendingRequests(for userID: String) async -> Result<
        [UserProfile], BluebirdAPIError
    >
    func sendFriendRequest(to userID: String) async -> Result<
        FriendRequestResponse, BluebirdAPIError
    >
    func removeFriend(friend userID: String) async -> Result<
        FriendRequestResponse, BluebirdAPIError
    >
    func respondToFriendRequest(to userID: String, accept: Bool) async
        -> Result<
            FriendRequestResponse, BluebirdAPIError
        >
    func createRepost(
        on entityType: EntityType,
        for entityID: String,
        caption: String
    ) async -> Result<PostCreatedResponse, BluebirdAPIError>
    func deleteRepost(postID: String) async -> Result<Void, BluebirdAPIError>
    func getCurrentUserReposts(
        cursor: String?,
        limit: Int?
    ) async -> Result<RepostsResponse, BluebirdAPIError>
    func getUserReposts(
        userID: String,
        cursor: String?,
        limit: Int?
    ) async -> Result<RepostsResponse, BluebirdAPIError>
    func getFeed(
        limit: Int?,
        offset: Int?
    ) async -> Result<FeedResponse, BluebirdAPIError>
    func getUnifiedFeed(
        limit: Int?,
        offset: Int?,
        includeHighlights: Bool
    ) async -> Result<UnifiedFeedResponse, BluebirdAPIError>
    func getLeaderboard(
        type: LeaderboardType,
        id: String,
        scope: LeaderboardScope
    ) async -> Result<LeaderboardResponse, BluebirdAPIError>
    func getTrendingTracks() async -> Result<[TrendingTrack], BluebirdAPIError>
    func getMilestones(userID: String) async -> Result<[UserMilestone], BluebirdAPIError>
}

protocol SpotifyAPIService {
    func getCurrentlyPlaying(spotifyAccessToken: String) async -> Result<
        SongDetail, BluebirdAPIError
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

struct SuccessResponse: Decodable {
    let message: String
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
