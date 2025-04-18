import SwiftUI

enum LoadingOrBool: Int {
    case loading, isfalse, istrue
}

/*

 need:
 spotifyRefreshToken
 supabaseRefreshToken

 */

class AppState: ObservableObject {
    @Published var isLoggedIn: LoadingOrBool
    @Published var isSpotifyConnected: LoadingOrBool

    init() {
        isLoggedIn = .loading
        isSpotifyConnected = .loading
    }

    func initAppState() async {
        isSpotifyConnected = .isfalse
        isLoggedIn = .isfalse
    }

    func signUp() async throws {
        // should create an account via supabase
        // return some status
        isLoggedIn = .istrue
    }

    func loginUser() async throws {
        // log in via supabase, return status
        isLoggedIn = .istrue
    }
}
