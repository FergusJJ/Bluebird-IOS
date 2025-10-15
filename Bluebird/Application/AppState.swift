import Foundation
import Supabase
import SwiftUI

enum LoadingOrBool: Int {
    case loading, isfalse, istrue
}

@MainActor
class AppState: ObservableObject {
    @Published var isLoggedIn: LoadingOrBool = .loading
    @Published var isSpotifyConnected: LoadingOrBool = .loading
    @Published var errorToDisplay: AppError?

    @AppStorage("userColorScheme") private var storedScheme: String = "system"
    @Published var userColorScheme: ColorScheme? = nil {
        didSet {
            storedScheme = userColorScheme == .dark ? "dark" :
                userColorScheme == .light ? "light" : "system"
        }
    }

    private var authListener: Task<Void, Never>?
    private var authAPIService: BluebirdAccountAPIService
    private var currentUserId: UUID?
    private var currentUserEmail: String?
    private var currentUsername: String?
    private var spotifyAccessToken: String?
    private var isEstablishingSpotifySession = false
    private var justSignedUp = false

    private let serviceID = "com.fergusjj.Bluebird"
    private func keychainAccountName(for type: String, userId: String) -> String {
        return "\(userId)-\(type)"
    }

    private let keychainAccessTokenType = "SPOTIFY_ACCESS_TOKEN"
    private let keychainRefreshTokenType = "SPOTIFY_REFRESH_TOKEN"

    @Published var currentSong: String = ""
    @Published var currentArtist: String = ""

    private let cacheManager = CacheManager.shared

    init() {
        do {
            authAPIService = try BluebirdAPIManagerV2()
        } catch {
            print(
                "FATAL ERROR: Failed to initialize BluebirdAPIManager: \(error.localizedDescription)"
            )
            fatalError(
                "Failed to initialize BluebirdAPIManager: \(error.localizedDescription)"
            )
        }
        switch storedScheme {
        case "dark": userColorScheme = .dark
        case "light": userColorScheme = .light
        default: userColorScheme = nil
        }
        setupAuthListener()
        initAppState()
    }

    deinit {
        print("AppState deinit: Cancelling auth listener.")
        authListener?.cancel()
    }

    func getSpotifyAccessToken() -> String? {
        return spotifyAccessToken
    }

    func setError(_ error: AppError) {
        errorToDisplay = error
    }

    func clearError() {
        errorToDisplay = nil
    }

    func handleAppDidBecomeActive() async {
        print("AppState: Handling app becoming active.")
        guard isLoggedIn == .istrue else {
            print(
                "AppState: App active, but user not logged in. Skipping Spotify check."
            )
            if isSpotifyConnected != .isfalse {
                isSpotifyConnected = .isfalse
                spotifyAccessToken = nil
            }
            return
        }

        print(
            "AppState: User logged in. Re-establishing Spotify session on foreground."
        )
        let connected = await establishSpotifySession()

        isSpotifyConnected = connected ? .istrue : .isfalse
        if connected {
            print(
                "AppState: Spotify session re-established successfully on foreground."
            )
        } else {
            print(
                "AppState: Failed to re-establish Spotify session on foreground."
            )
        }
    }

    // only used when no spotify connection linked to account, saves spotify client id
    func handleInitialSpotifyConnection(
        accessToken: String,
        refreshToken: String,
        tokenExpiry: String,
        scopes: String
    ) async {
        print("AppState: Handling initial spotify connection")
        guard isLoggedIn == .istrue else {
            print(
                "AppState: App active, but user not logged in. Cannot save initial spotify connection"
            )
            if isSpotifyConnected != .isfalse {
                isSpotifyConnected = .isfalse
                spotifyAccessToken = nil
            }
            return
        }
        print(
            "AppState: User logged in. Proceeding with initial spotify connection"
        )
        let connected = await establishSpotifySessionClientID(
            accessToken: accessToken,
            refreshToken: refreshToken,
            tokenExpiry: tokenExpiry,
            scopes: scopes
        )
        isSpotifyConnected = connected ? .istrue : .isfalse
        if connected {
            print(
                "AppState: Spotify intial session established successfully on foreground."
            )
        } else {
            print(
                "AppState: Failed to establish Spotify initial session on foreground."
            )
        }
    }

    func initAppState() {
        Task {
            do {
                _ = try await SupabaseClientManager.shared.client.auth
                    .refreshSession()
            } catch {
                print(
                    "AppState init: Failed to refresh Supabase session: \(error.localizedDescription)"
                )
                self.isLoggedIn = .isfalse
                self.isSpotifyConnected = .isfalse
                self.currentUserId = nil
                self.currentUserEmail = nil
                self.currentUsername = nil
                await self.clearSpotifyTokens()
                await self.clearUserCache()
            }
        }
    }

    private func setupAuthListener() {
        authListener = Task { [weak self] in
            for await event in SupabaseClientManager.shared.client.auth
                .authStateChanges
            {
                print("AUTH-LISTENER: EVENT RECIEVED: \(event.event)")
                guard let self = self else {
                    print(
                        "Auth listener exiting: AppState instance deallocated."
                    )
                    return
                }

                var newLoggedInState = self.isLoggedIn
                var newSpotifyState = self.isSpotifyConnected
                var newUserID = self.currentUserId

                switch event.event {
                case .signedIn, .initialSession:
                    if let user = event.session?.user {
                        newLoggedInState = .istrue
                        newUserID = user.id
                        self.currentUserId = newUserID
                        self.currentUserEmail = user.email
                        await self.setupUserCache(
                            userId: user.id.uuidString,
                            email: user.email ?? ""
                        )

                        if justSignedUp {
                            print(
                                "Auth Listener: User just signed up, skipping Spotify session establishment."
                            )
                            justSignedUp = false // Reset the flag
                            newSpotifyState = .isfalse
                        } else if self.isSpotifyConnected != .istrue {
                            print(
                                "Auth Listener: Spotify not connected for \(event.event), attempting to establish session..."
                            )
                            let spotifyConnected =
                                await self.establishSpotifySession()
                            newSpotifyState =
                                spotifyConnected ? .istrue : .isfalse
                            if !spotifyConnected {
                                print(
                                    "Auth Listener: Failed to establish Spotify session."
                                )
                            } else {
                                print(
                                    "Auth Listener: Spotify session established successfully via listener for \(event.event)."
                                )
                            }

                        } else {
                            print(
                                "Auth Listener: Spotify already connected during \(event.event), skipping establish call."
                            )
                            newSpotifyState = .istrue
                        }
                    } else {
                        print(
                            "Auth Listener: \(event.event) event but session/user is nil. Treating as logged out."
                        )
                        newLoggedInState = .isfalse
                        newSpotifyState = .isfalse
                        newUserID = nil
                        await self.clearSpotifyTokens()
                        await self.clearUserCache()
                    }

                // happens slightly after session is initialized, don't establish spotify session
                case .tokenRefreshed:
                    print("Auth Listener: Event tokenRefreshed.")
                    if let user = event.session?.user {
                        newUserID = user.id
                        self.currentUserId = newUserID
                        self.currentUserEmail = user.email
                        newLoggedInState = .istrue
                    } else {
                        print(
                            "Auth Listener: tokenRefreshed event but session/user is nil. Treating as logged out."
                        )
                        newLoggedInState = .isfalse
                        newSpotifyState = .isfalse
                        newUserID = nil
                        await self.clearSpotifyTokens()
                        await self.clearUserCache()
                    }

                case .signedOut:
                    print("Auth Listener: User signed out.")
                    newLoggedInState = .isfalse
                    newSpotifyState = .isfalse
                    newUserID = nil
                    await self.clearSpotifyTokens()
                    await self.clearUserCache()

                case .passwordRecovery, .userUpdated, .userDeleted:
                    print("Auth Listener: Event \(event.event) received.")
                    if let user = event.session?.user {
                        newUserID = user.id
                        self.currentUserId = newUserID
                        self.currentUserEmail = user.email
                    } else if event.event == .userDeleted {
                        newLoggedInState = .isfalse
                        newSpotifyState = .isfalse
                        newUserID = nil
                        await self.clearSpotifyTokens()
                        await self.clearUserCache()
                    }

                default:
                    print("AuthListener: unhandled event: \(event.event)")
                }

                print("AUTH-LISTENER: END")
                self.isLoggedIn = newLoggedInState
                self.isSpotifyConnected = newSpotifyState
                self.currentUserId = newUserID
                if newLoggedInState == .istrue
                    && newSpotifyState == .istrue
                {
                    self.clearError()
                }
            }
            print("Auth Listener: Auth stream terminated.")
        }
    }

    func signUp(email: String, username: String, password: String) async
        -> Bool
    {
        // auth.signUp emits the event, so justSignedUp has to be set first
        justSignedUp = true
        do {
            let authResponse = try await SupabaseClientManager.shared.client
                .auth.signUp(
                    email: email,
                    password: password
                )
            let userId = authResponse.user.id
            currentUsername = username
            let result = await authAPIService.userSignUp(username: username)
            switch result {
            case .success:
                print("Profile Insert successful for user ID \(userId)")
                // Setup cache for new user
                await setupUserCache(
                    userId: userId.uuidString,
                    email: email,
                    username: username
                )
                return true
            case let .failure(serviceError):
                print("Failed to create user profile: \(serviceError)")
                let presentationError = AppError(from: serviceError)
                setError(presentationError)
                return false
            }
        } catch let authError as AuthError {
            print("Auth Sign Up Error: \(authError.localizedDescription)")
            let supabaseError = SupabaseError.signupFailed(authError)
            let presentationError = AppError(from: supabaseError)
            setError(presentationError)
            return false
        } catch {
            print(
                "Sign Up Error: An unexpected error occurred - \(error.localizedDescription)"
            )
            let appError = AppStateError.genericError("An unexpected error occurred.")
            let presentationError = AppError(from: appError)
            setError(presentationError)
            return false
        }
    }

    func loginUser(email: String, password: String) async -> Bool {
        do {
            _ = try await SupabaseClientManager.shared.client.auth.signIn(
                email: email,
                password: password
            )
            return true
        } catch {
            print("Error logging in: \(error.localizedDescription)")
            let supbaseError = SupabaseError.loginFailed(error)
            let presentableError = AppError(from: supbaseError)
            setError(presentableError)
            return false
        }
    }

    func logoutUser() async -> Bool {
        do {
            print("Cleasring cache")
            await clearUserCache()
            print("Cleared cache")

            try await SupabaseClientManager.shared.client.auth.signOut()
            print("User logged out successfully.")

            // Reset local state
            currentUserId = nil
            currentUserEmail = nil
            currentUsername = nil
            currentSong = ""
            currentArtist = ""

            return true
        } catch {
            print("Error signing out: \(error.localizedDescription)")
            let supabaseError = SupabaseError.logoutFailed(error)
            let presentationError = AppError(from: supabaseError)
            setError(presentationError)
            return false
        }
    }

    func deleteUser() async -> Bool {
        let result = await SupabaseClientManager.shared.deleteAccount()
        switch result {
        case .success():
            await clearUserCache()
            _ = await logoutUser()
            return true
        case let .failure(error):
            print("Error deleting account: \(error.localizedDescription)")
            let supabaseError = SupabaseError.deleteAccountFailed(error)
            let presentationError = AppError(from: supabaseError)
            setError(presentationError)
            return false
        }
    }

    func connectSpotify() async -> Bool {
        guard currentUserId != nil else {
            print("Connect Spotify Error: User not logged in.")
            let appStateError = AppStateError.userNotLoggedIn
            let presentationError = AppError(from: appStateError)
            setError(presentationError)
            return false
        }

        let result = await authAPIService.initiateSpotifyConnection()

        switch result {
        case .success:
            print("Spotify authorization flow initiated successfully.")
            clearError()
            return true
        case let .failure(error):
            print(
                "Error initiating Spotify authorization flow: \(error.localizedDescription)"
            )
            let appStateErr = AppStateError.genericError(
                "Failed to connect spotify: \(error.localizedDescription)"
            )
            let presentationError = AppError(from: appStateErr)
            setError(presentationError)
            return false
        }
        // previously returned here, but want to make sure that spotify client id is fetched
    }

    func saveSpotifyCredentials(access: String, refresh: String, tokenExpiry: String, scopes: String) -> Bool {
        guard let userId = currentUserId else {
            let error = AppStateError.userNotLoggedIn
            let presentationError = AppError(from: error)
            setError(presentationError)
            return false
        }
        let userIdString = userId.uuidString

        let accessAccount = keychainAccountName(
            for: keychainAccessTokenType,
            userId: userIdString
        )
        let refreshAccount = keychainAccountName(
            for: keychainRefreshTokenType,
            userId: userIdString
        )

        guard let accessTokenData = access.data(using: .utf8),
              let refreshTokenData = refresh.data(using: .utf8)
        else {
            print(
                "SaveSpotifyCredentials Error: Could not encode tokens to Data."
            )
            let error = AppStateError.keychainError("Token encoding failed")
            let presentationError = AppError(from: error)
            setError(presentationError)
            return false
        }
        let accessSuccess = KeychainManager.storeData(
            data: accessTokenData,
            service: serviceID,
            account: accessAccount
        )
        let refreshSuccess = KeychainManager.storeData(
            data: refreshTokenData,
            service: serviceID,
            account: refreshAccount
        )

        if accessSuccess && refreshSuccess {
            print(
                "SaveSpotifyCredentials: Tokens saved successfully to keychain."
            )

            spotifyAccessToken = access
            isSpotifyConnected = .istrue
            clearError()

            Task {
                await uploadSpotifyRefreshTokenToDatabase(
                    accessToken: access,
                    refreshToken: refresh,
                    tokenExpiry: tokenExpiry,
                    scopes: scopes
                )
            }
            return true // Success
        } else {
            print(
                "SaveSpotifyCredentials Error: Failed to store one or both tokens in Keychain. accessSuccess=\(accessSuccess), refreshSuccess=\(refreshSuccess)"
            )
            _ = KeychainManager.deleteData(
                service: serviceID,
                account: accessAccount
            )
            _ = KeychainManager.deleteData(
                service: serviceID,
                account: refreshAccount
            )

            isSpotifyConnected = .isfalse
            spotifyAccessToken = nil
            let error = AppStateError.keychainError(
                "Failed to save Spotify credentials to keychain."
            )
            let presentationError = AppError(from: error)
            setError(presentationError)
            return false
        }
    }

    // MARK: - Cache stuff

    @MainActor
    private func setupUserCache(userId: String, email: String, username: String? = nil) async {
        // Try to get username if not provided
        let finalUsername: String
        if let username = username {
            finalUsername = username
        } else if let cachedUsername = currentUsername {
            finalUsername = cachedUsername
        } else {
            let result = await authAPIService.getProfile()
            switch result {
            case let .success(profile):
                finalUsername = profile.username
                currentUsername = profile.username
            case .failure:
                finalUsername = email.components(separatedBy: "@").first ?? "User"
            }
        }

        cacheManager.setCurrentUser(
            userId: userId,
            username: finalUsername,
            email: email
        )
    }

    @MainActor
    private func clearUserCache() async {
        cacheManager.clearCurrentUserData()
    }

    @MainActor
    private func establishSpotifySessionClientID(
        accessToken: String,
        refreshToken: String,
        tokenExpiry: String,
        scopes: String
    ) async -> Bool {
        guard !isEstablishingSpotifySession else {
            print(
                "EstablishSpotifySessionClientID SKIPPED: Already in progress."
            )
            return isSpotifyConnected == .istrue
        }
        isEstablishingSpotifySession = true
        defer {
            print(
                "EstablishSpotifySessionClientID: Resetting isEstablishingSpotifySession flag."
            )
            isEstablishingSpotifySession = false
        }
        guard let userId = currentUserId else {
            print("EstablishSpotifySession Error: Missing User ID.")
            let appError = AppStateError.missingUserID
            let presentationError = AppError(from: appError)
            setError(presentationError)
            return false
        }
        let userIdString = userId.uuidString
        print(
            "EstablishSpotifySessionClientID: Attempting to fetch/refresh Spotify access token via API..."
        )
        let result = await authAPIService.saveSpotifyAccessTokenClientID(
            accessToken: accessToken,
            refreshToken: refreshToken,
            tokenExpiry: tokenExpiry,
            scopes: scopes
        )
        switch result {
        case let .success(newAccessToken):
            print(
                "EstablishSpotifySessionClientID: Successfully fetched new access token."
            )
            spotifyAccessToken = newAccessToken
            let accessAccount = keychainAccountName(
                for: keychainAccessTokenType,
                userId: userIdString
            )
            if let accessTokenData = newAccessToken.data(using: .utf8) {
                let success = KeychainManager.storeData(
                    data: accessTokenData,
                    service: serviceID,
                    account: accessAccount
                )
                success
                    ? print("EstablishSpotifySessionClientID: Saved new access token to keychain.")
                    : print(
                        "EstablishSpotifySessionClientID Warning: Failed to save new access token to keychain."
                    )
            } else {
                print(
                    "EstablishSpotifySessionClientID Warning: Could not encode access token to save to keychain."
                )
            }
            return true
        case let .failure(serviceError):
            print(
                "EstablishSpotifySessionClientID Error: Failed to establish session via API - \(serviceError.localizedDescription)"
            )
            let presentationError = AppError(from: serviceError)
            setError(presentationError)
            spotifyAccessToken = nil
            let accessAccount = keychainAccountName(
                for: keychainAccessTokenType,
                userId: userIdString
            )
            let deleted = KeychainManager.deleteData(
                service: serviceID,
                account: accessAccount
            )
            if !deleted {
                print(
                    "EstablishSpotifySessionClientID Warning: Failed to delete access token from keychain (it might not have existed)."
                )
            }
            return false
        }
    }

    @MainActor
    private func establishSpotifySession() async -> Bool {
        guard !isEstablishingSpotifySession else {
            print("EstablishSpotifySession SKIPPED: Already in progress.")
            return isSpotifyConnected == .istrue
        }
        isEstablishingSpotifySession = true
        defer {
            print(
                "EstablishSpotifySession: Resetting isEstablishingSpotifySession flag."
            )
            isEstablishingSpotifySession = false
        }

        guard let userId = currentUserId else {
            print("EstablishSpotifySession Error: Missing User ID.")
            let appError = AppStateError.missingUserID
            let presentationError = AppError(from: appError)
            setError(presentationError)
            return false
        }
        let userIdString = userId.uuidString
        print(
            "EstablishSpotifySession: Attempting to fetch/refresh Spotify access token via API..."
        )
        let result = await authAPIService.refreshSpotifyAccessToken()

        switch result {
        case let .success(newAccessToken):
            print(
                "EstablishSpotifySession: Successfully fetched new access token."
            )
            spotifyAccessToken = newAccessToken
            let accessAccount = keychainAccountName(
                for: keychainAccessTokenType,
                userId: userIdString
            )
            if let accessTokenData = newAccessToken.data(using: .utf8) {
                let success = KeychainManager.storeData(
                    data: accessTokenData,
                    service: serviceID,
                    account: accessAccount
                )
                success
                    ? print(
                        "EstablishSpotifySession: Saved new access token to keychain."
                    )
                    : print(
                        "EstablishSpotifySession Warning: Failed to save new access token to keychain."
                    )
            } else {
                print(
                    "EstablishSpotifySession Warning: Could not encode access token to save to keychain."
                )
            }

            return true

        case let .failure(serviceError):
            switch serviceError {
            case let .apiError(statusCode, _) where statusCode == 404:
                print(
                    "EstablishSpotifySession: User has not spotify session in DB. Assuming first login."
                )
                return false
            default:
                print(
                    "EstablishSpotifySession Error: Failed to establish spotify session - \(serviceError.localizedDescription)"
                )
            }
            spotifyAccessToken = nil
            let accessAccount = keychainAccountName(
                for: keychainAccessTokenType,
                userId: userIdString
            )
            let deleted = KeychainManager.deleteData(
                service: serviceID,
                account: accessAccount
            )
            if !deleted {
                print(
                    "EstablishSpotifySession Warning: Failed to delete access token from keychain (it might not have existed)."
                )
            }
            let presentationError = AppError(from: serviceError)
            setError(presentationError)
            return false
        }
    }

    private func uploadSpotifyRefreshTokenToDatabase(
        accessToken: String,
        refreshToken: String,
        tokenExpiry: String,
        scopes: String
    ) async {
        let result = await authAPIService.saveSpotifyAccessTokenClientID(
            accessToken: accessToken,
            refreshToken: refreshToken,
            tokenExpiry: tokenExpiry,
            scopes: scopes
        )
        switch result {
        case .success:
            print("Successfully uploaded/updated refresh token in DB.")
        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            setError(presentationError)
        }
    }

    private func clearSpotifyTokens() async {
        print("Clearing Spotify access token from memory and keychain.")
        spotifyAccessToken = nil

        guard let userId = currentUserId else {
            print("ClearSpotifyTokens Warning: No current user ID found.")
            return
        }
        let userIdString = userId.uuidString

        let accessAccount = keychainAccountName(
            for: keychainAccessTokenType,
            userId: userIdString
        )
        let refreshAccount = keychainAccountName(
            for: keychainRefreshTokenType,
            userId: userIdString
        )
        if !KeychainManager.deleteData(
            service: serviceID,
            account: accessAccount
        ) {
            print(
                "ClearSpotifyTokens Info: Failed to delete access token from keychain (or not found)."
            )
        }
        if !KeychainManager.deleteData(
            service: serviceID,
            account: refreshAccount
        ) {
            print(
                "ClearSpotifyTokens Info: Failed to delete refresh token from keychain (or not found)."
            )
        }
    }
}
