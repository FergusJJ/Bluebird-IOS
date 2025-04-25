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
    private var apiManager: BluebirdAPIManager
    private var currentUserId: UUID?
    private var spotifyAccessToken: String?
    private var isEstablishingSpotifySession = false

    private let serviceID = "com.fergusjj.Bluebird"
    private func keychainAccountName(for type: String, userId: String) -> String {
        return "\(userId)-\(type)"
    }

    private let keychainAccessTokenType = "SPOTIFY_ACCESS_TOKEN"
    private let keychainRefreshTokenType = "SPOTIFY_REFRESH_TOKEN"

    init() {
        do {
            apiManager = try BluebirdAPIManager()
        } catch {
            print(
                "FATAL ERROR: Failed to initialize BluebirdAPIManager: \(error.localizedDescription)"
            )
            fatalError("Failed to initialize BluebirdAPIManager: \(error.localizedDescription)")
        }

        setupAuthListener()
        initAppState()
    }

    deinit {
        print("AppState deinit: Cancelling auth listener.")
        authListener?.cancel()
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
            print("AppState: App active, but user not logged in. Skipping Spotify check.")
            if isSpotifyConnected != .isfalse {
                isSpotifyConnected = .isfalse
                spotifyAccessToken = nil
            }
            return
        }

        print("AppState: User logged in. Re-establishing Spotify session on foreground.")
        let (connected, error) = await establishSpotifySession()

        isSpotifyConnected = connected ? .istrue : .isfalse
        if error != nil {
            setError(error!)
        }

        if connected {
            print("AppState: Spotify session re-established successfully on foreground.")
        } else {
            print(
                "AppState: Failed to re-establish Spotify session on foreground. Error: \(error?.localizedDescription ?? "N/A")"
            )
        }
    }

    func initAppState() {
        Task {
            do {
                _ = try await SupabaseClientManager.shared.client.auth.refreshSession()
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
            for await event in SupabaseClientManager.shared.client.auth.authStateChanges {
                print("AUTH-LISTENER: EVENT RECIEVED: \(event.event)")
                guard let self = self else {
                    print("Auth listener exiting: AppState instance deallocated.")
                    return
                }

                var newLoggedInState = self.isLoggedIn
                var newSpotifyState = self.isSpotifyConnected
                var newUserID = self.currentUserId
                var connectionError: Error? = nil

                switch event.event {
                case .signedIn, .initialSession:
                    if let user = event.session?.user {
                        newLoggedInState = .istrue
                        newUserID = user.id
                        self.currentUserId = newUserID
                        if self.isSpotifyConnected != .istrue {
                            print(
                                "Auth Listener: Spotify not connected for \(event.event), attempting to establish session..."
                            )
                            let (spotifyConnected, spotifyError) =
                                await self.establishSpotifySession()
                            newSpotifyState = spotifyConnected ? .istrue : .isfalse
                            connectionError = spotifyError
                            if !spotifyConnected {
                                print(
                                    "Auth Listener: Failed to establish Spotify session. Error: \(spotifyError?.localizedDescription ?? "N/A")"
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
                if let error = connectionError {
                    self.setError(error)
                } else if newLoggedInState == .istrue && newSpotifyState == .istrue {
                    self.clearError()
                }
            }
            print("Auth Listener: Auth stream terminated.")
        }
    }

    func signUp(email: String, username: String, password: String) async -> SignUpError? {
        var createdAuthUserId: UUID?
        do {
            let authResponse = try await SupabaseClientManager.shared.client.auth.signUp(
                email: email, password: password
            )
            let userId = authResponse.user.id
            createdAuthUserId = userId

            struct SignUpProfile: Encodable {
                let id: UUID
                let username: String
            }
            let signUpProfile = SignUpProfile(id: userId, username: username)

            try await SupabaseClientManager.shared.client
                .from("profiles")
                .insert(signUpProfile)
                .execute()

            print("Profile Insert successful for user ID \(userId).")
            return nil // Success

        } catch let authError as AuthError {
            print("Auth Sign Up Error: \(authError.localizedDescription)")
            return SignUpError.authFailed(authError)
        } catch let postgrestError as PostgrestError {
            print("Profile Insert Error: \(postgrestError.localizedDescription)")
            if let createdUserId = createdAuthUserId {
                print(
                    "Error occurred after Auth User \(createdUserId) was created. Profile insert failed."
                )
                return SignUpError.profileInsertFailed(postgrestError)
            } else {
                return SignUpError.profileInsertFailed(postgrestError)
            }
        } catch {
            print("Sign Up Error: An unexpected error occurred - \(error.localizedDescription)")
            if createdAuthUserId != nil {
                return SignUpError.profileInsertFailed(error)
            } else {
                return SignUpError.authFailed(error)
            }
        }
    }

    func loginUser(email: String, password: String) async -> Error? {
        do {
            _ = try await SupabaseClientManager.shared.client.auth.signIn(
                email: email, password: password
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

        let result = await apiManager.initiateSpotifyConnection()

        switch result {
        case .success:
            print("Spotify authorization flow initiated successfully.")
            clearError()
            return nil
        case let .failure(error):
            print("Error initiating Spotify authorization flow: \(error.localizedDescription)")
            let err = AppStateError.genericError(
                "Failed to connect spotify: \(error.localizedDescription)")
            self.setError(err)
            return err
        }
    }

    func saveSpotifyCredentials(access: String, refresh: String) -> Error? {
        guard let userId = currentUserId else {
            let error = AppStateError.userNotLoggedIn
            setError(error)
            return error
        }
        let userIdString = userId.uuidString

        let accessAccount = keychainAccountName(for: keychainAccessTokenType, userId: userIdString)
        let refreshAccount = keychainAccountName(
            for: keychainRefreshTokenType, userId: userIdString
        )

        guard let accessTokenData = access.data(using: .utf8),
              let refreshTokenData = refresh.data(using: .utf8)
        else {
            print("SaveSpotifyCredentials Error: Could not encode tokens to Data.")
            let error = AppStateError.keychainError("Token encoding failed")
            setError(error)
            return error
        }
        let accessSuccess = KeychainManager.storeData(
            data: accessTokenData, service: serviceID, account: accessAccount
        )
        let refreshSuccess = KeychainManager.storeData(
            data: refreshTokenData, service: serviceID, account: refreshAccount
        )

        if accessSuccess && refreshSuccess {
            print("SaveSpotifyCredentials: Tokens saved successfully to keychain.")

            spotifyAccessToken = access
            isSpotifyConnected = .istrue
            clearError()

            Task {
                await uploadSpotifyRefreshTokenToDatabase(
                    refreshToken: refresh, userId: userIdString
                )
            }

            return nil // Success
        } else {
            print(
                "SaveSpotifyCredentials Error: Failed to store one or both tokens in Keychain. accessSuccess=\(accessSuccess), refreshSuccess=\(refreshSuccess)"
            )
            _ = KeychainManager.deleteData(service: serviceID, account: accessAccount)
            _ = KeychainManager.deleteData(service: serviceID, account: refreshAccount)

            isSpotifyConnected = .isfalse
            spotifyAccessToken = nil
            let error = AppStateError.keychainError(
                "Failed to save Spotify credentials to keychain.")
            setError(error)
            return error
        }
    }

    @MainActor
    private func establishSpotifySession() async -> (connected: Bool, err: Error?) {
        guard !isEstablishingSpotifySession else {
            print("EstablishSpotifySession SKIPPED: Already in progress.")
            return (isSpotifyConnected == .istrue, errorToDisplay?.underlyingError)
        }
        isEstablishingSpotifySession = true
        defer {
            print("EstablishSpotifySession: Resetting isEstablishingSpotifySession flag.")
            isEstablishingSpotifySession = false
        }

        guard let userId = currentUserId else {
            print("EstablishSpotifySession Error: Missing User ID.")
            return (false, AppStateError.missingUserID)
        }
        let userIdString = userId.uuidString

        print(
            "EstablishSpotifySession: Attempting to fetch/refresh Spotify access token via API...")
        let result = await apiManager.refreshSpotifyAccessToken()

        switch result {
        case let .success(newAccessToken):
            print("EstablishSpotifySession: Successfully fetched new access token.")
            spotifyAccessToken = newAccessToken
            let accessAccount = keychainAccountName(
                for: keychainAccessTokenType, userId: userIdString
            )
            if let accessTokenData = newAccessToken.data(using: .utf8) {
                let success = KeychainManager.storeData(
                    data: accessTokenData, service: serviceID, account: accessAccount
                )
                if success {
                    print("EstablishSpotifySession: Saved new access token to keychain.")
                } else {
                    print(
                        "EstablishSpotifySession Warning: Failed to save new access token to keychain."
                    )
                }
            } else {
                print(
                    "EstablishSpotifySession Warning: Could not encode access token to save to keychain."
                )
            }

            return (true, nil)

        case let .failure(error):
            print(
                "EstablishSpotifySession Error: Failed to establish session via API - \(error.localizedDescription)"
            )
            setError(error)
            spotifyAccessToken = nil
            let accessAccount = keychainAccountName(
                for: keychainAccessTokenType, userId: userIdString
            )
            let deleted = KeychainManager.deleteData(service: serviceID, account: accessAccount)
            if !deleted {
                print(
                    "EstablishSpotifySession Warning: Failed to delete access token from keychain (it might not have existed)."
                )
            }
            return (false, error)
        }
    }

    private func uploadSpotifyRefreshTokenToDatabase(refreshToken: String, userId: String) async {
        struct SpotifyDataUpdate: Encodable {
            let id: String
            let refresh_token: String
        }
        let dataToUpload = SpotifyDataUpdate(id: userId, refresh_token: refreshToken)

        do {
            try await SupabaseClientManager.shared.client
                .from("spotify")
                .upsert(dataToUpload)
                .execute()
            print("Successfully uploaded/updated refresh token in DB.")
        } catch let err as PostgrestError {
            print("Error uploading refresh token to DB: \(err.localizedDescription)")
            let error = DatabaseError.uploadFailed(err)
            self.setError(error)
        } catch {
            print("Error uploading refresh token to DB (unexpected): \(error.localizedDescription)")
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

        let accessAccount = keychainAccountName(for: keychainAccessTokenType, userId: userIdString)
        let refreshAccount = keychainAccountName(
            for: keychainRefreshTokenType, userId: userIdString
        )
        if !KeychainManager.deleteData(service: serviceID, account: accessAccount) {
            print(
                "ClearSpotifyTokens Info: Failed to delete access token from keychain (or not found)."
            )
        }
        if !KeychainManager.deleteData(service: serviceID, account: refreshAccount) {
            print(
                "ClearSpotifyTokens Info: Failed to delete refresh token from keychain (or not found)."
            )
        }
    }
}
