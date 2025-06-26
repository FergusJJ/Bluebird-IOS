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
    @Published var errorToDisplay: DisplayableError?

    private var authListener: Task<Void, Never>?
    private var authAPIService: BluebirdAuthAPIService
    private var currentUserId: UUID?
    private var spotifyAccessToken: String?
    private var isEstablishingSpotifySession = false
    private var justSignedUp = false

    private let serviceID = "com.fergusjj.Bluebird"
    private func keychainAccountName(for type: String, userId: String) -> String {
        return "\(userId)-\(type)"
    }

    private let keychainAccessTokenType = "SPOTIFY_ACCESS_TOKEN"
    private let keychainRefreshTokenType = "SPOTIFY_REFRESH_TOKEN"

    init() {
        do {
            authAPIService = try BluebirdAPIManager()
        } catch {
            print(
                "FATAL ERROR: Failed to initialize BluebirdAPIManager: \(error.localizedDescription)"
            )
            fatalError(
                "Failed to initialize BluebirdAPIManager: \(error.localizedDescription)"
            )
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

    private func setError(_ error: Error) {
        errorToDisplay = DisplayableError(underlyingError: error)
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
        tokenExpiry: String
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
            tokenExpiry: tokenExpiry
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
                await self.clearSpotifyTokens()
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
                    }

                // happens slightly after session is initialized, don't establish spotify session
                case .tokenRefreshed:
                    print("Auth Listener: Event tokenRefreshed.")
                    if let user = event.session?.user {
                        newUserID = user.id
                        self.currentUserId = newUserID
                        newLoggedInState = .istrue
                    } else {
                        print(
                            "Auth Listener: tokenRefreshed event but session/user is nil. Treating as logged out."
                        )
                        newLoggedInState = .isfalse
                        newSpotifyState = .isfalse
                        newUserID = nil
                        await self.clearSpotifyTokens()
                    }

                case .signedOut:
                    print("Auth Listener: User signed out.")
                    newLoggedInState = .isfalse
                    newSpotifyState = .isfalse
                    newUserID = nil
                    await self.clearSpotifyTokens()

                case .passwordRecovery, .userUpdated, .userDeleted:
                    print("Auth Listener: Event \(event.event) received.")
                    if let user = event.session?.user {
                        newUserID = user.id
                        self.currentUserId = newUserID
                    } else if event.event == .userDeleted {
                        newLoggedInState = .isfalse
                        newSpotifyState = .isfalse
                        newUserID = nil
                        await self.clearSpotifyTokens()
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
        -> Error?
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
            let result = await authAPIService.userSignUp(username: username)
            switch result {
            case .success:
                print("Profile Insert successful for user ID \(userId)")
                return nil
            case let .failure(error):
                print("Failed to create user profile: \(error)")
                return error
            }
        } catch let authError as AuthError {
            print("Auth Sign Up Error: \(authError.localizedDescription)")
            return SignUpError.authFailed(authError)
        } catch {
            print(
                "Sign Up Error: An unexpected error occurred - \(error.localizedDescription)"
            )
            return SignUpError.authFailed(error)
        }
    }

    func loginUser(email: String, password: String) async -> Error? {
        do {
            _ = try await SupabaseClientManager.shared.client.auth.signIn(
                email: email,
                password: password
            )
            return nil
        } catch {
            print("Error logging in: \(error.localizedDescription)")
            return error
        }
    }

    func logoutUser() async -> SignOutError? {
        do {
            try await SupabaseClientManager.shared.client.auth.signOut()
            print("User logged out successfully.")
            return nil
        } catch {
            print("Error signing out: \(error.localizedDescription)")
            return SignOutError.unexpectedError
        }
    }

    func connectSpotify() async -> Error? {
        guard currentUserId != nil else {
            print("Connect Spotify Error: User not logged in.")
            let error = AppStateError.userNotLoggedIn
            setError(error)
            return error
        }

        let result = await authAPIService.initiateSpotifyConnection()

        switch result {
        case .success:
            print("Spotify authorization flow initiated successfully.")
            clearError()
            return nil
        case let .failure(error):
            print(
                "Error initiating Spotify authorization flow: \(error.localizedDescription)"
            )
            let err = AppStateError.genericError(
                "Failed to connect spotify: \(error.localizedDescription)"
            )
            setError(err)
            return err
        }
        // previously returned here, but want to make sure that spotify client id is fetched
    }

    func saveSpotifyCredentials(access: String, refresh: String, tokenExpiry: String) -> Bool {
        guard let userId = currentUserId else {
            let error = AppStateError.userNotLoggedIn
            let presentationError = APIError(from: error)
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
            let presentationError = APIError(from: error)
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
            let presentationError = APIError(from: error)
            setError(presentationError)
            return false
        }
    }

    @MainActor
    private func establishSpotifySessionClientID(
        accessToken: String,
        refreshToken: String,
        tokenExpiry: String
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
            let presentationError = APIError(from: appError)
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
            tokenExpiry: tokenExpiry
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
            let presentationError = APIError(from: serviceError)
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
            let presentationError = APIError(from: appError)
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
            let presentationError = APIError(from: serviceError)
            setError(presentationError)
            return false
        }
    }

    private func uploadSpotifyRefreshTokenToDatabase(
        accessToken: String,
        refreshToken: String,
        tokenExpiry: String,
    ) async {
        let result = await authAPIService.upsertSpotifyRefreshToken(
            accessToken: accessToken,
            refreshToken: refreshToken,
            tokenExipryString: tokenExpiry
        )
        switch result {
        case .success:
            print("Successfully uploaded/updated refresh token in DB.")
        case let .failure(serviceError):
            let presentationError = APIError(from: serviceError)
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
