import Foundation
import SwiftUI

enum LoadingOrBool: Int {
    case loading, isfalse, istrue
}

/*

 need:
 spotifyRefreshToken
 supabaseRefreshToken

 */

@MainActor
class AppState: ObservableObject {
    @Published var isLoggedIn: LoadingOrBool
    @Published var isSpotifyConnected: LoadingOrBool

    private var authListener: Task<Void, Never>?

    init() {
        isLoggedIn = .loading
        isSpotifyConnected = .loading

        initAppState()
        authListener = Task {
            for await event in SupabaseClientManager.shared.client.auth
                .authStateChanges
            {
                if event.session != nil {
                    self.isLoggedIn = .istrue
                } else {
                    self.isLoggedIn = .isfalse
                }
            }
        }
    }

    deinit {
        authListener?.cancel()
    }

    func initAppState() {
        Task {
            do {
                _ = try await SupabaseClientManager.shared.client.auth
                    .refreshSession()
                isLoggedIn = .istrue
            } catch {
                print("failed to refresh session: \(error)")
                isLoggedIn = .isfalse
            }
        }
        Task {
            isSpotifyConnected = .isfalse
        }
    }

    func signUp(email: String, username: String, password: String) async -> Error? {
        var createdAuthUserId: UUID?
        do {
            let authResponse = try await SupabaseClientManager.shared.client.auth
                .signUp(
                    email: email,
                    password: password
                )
            let userId = authResponse.user.id
            if authResponse.session == nil {
                print("Auth Sign Up Error: Missing User ID in response.")
                return SignUpError.missingUserID
            }
            createdAuthUserId = userId
            let signUpProfile = SignUpProfile(id: userId, username: username)

            print("Attempting Profile Insert for user ID \(userId)...")
            let profileInsertResponse = try? await SupabaseClientManager.shared.client
                .from("profiles")
                .insert(signUpProfile)
                .execute()

            guard let httpResponse = profileInsertResponse?.response else {
                print("Profile Insert Error: Could not parse HTTP response.")
                return SignUpError.couldNotParseResponseDetails
            }

            let statusCode = httpResponse.statusCode
            if (200 ..< 300).contains(statusCode) {
                return nil
            } else {
                print("Profile Insert Failure: Unexpected Status Code \(statusCode).")
                return SignUpError.profileInsertUnexpectedStatusCode(statusCode)
            }

        } catch {
            if let createdUserId = createdAuthUserId {
                print(
                    "Error occurred after Auth User \(createdUserId) was created. Profile insert failed."
                )
                return SignUpError.profileInsertFailed(error)
            } else {
                print("Error occurred during Auth Sign Up.")
                return SignUpError.authFailed(error)
            }
        }
    }

    func loginUser(email: String, password: String) async -> Error? {
        do {
            _ = try await SupabaseClientManager.shared.client.auth
                .signIn(email: email, password: password)
            return nil
        } catch {
            print("Error logging in: \(error)")
            return error
        }
    }
}
