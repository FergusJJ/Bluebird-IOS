import Foundation
import Supabase

class SupabaseClientManager {
    static let shared = SupabaseClientManager()
    let client: SupabaseClient

    private init() {
        guard let path = Bundle.main.path(forResource: "SupabaseCredentials", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject]
        else {
            fatalError("SupabaseCredentials.plist not found or invalid format.")
        }

        guard let urlString = dict["SUPABASE_URL"] as? String,
              let supabaseURL = URL(string: urlString),
              let supabaseKey = dict["SUPABASE_ANON_KEY"] as? String
        else {
            fatalError(
                "SUPABASE_URL or SUPABASE_ANON_KEY not found or invalid in SupabaseCredentials.plist."
            )
        }
        if supabaseKey.isEmpty || supabaseKey == "your_actual_anon_key_here" {
            fatalError(
                "Supabase Anon Key is missing or placeholder value used in SupabaseCredentials.plist."
            )
        }

        client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)

        // this was just for logging stuff
        // Task {
        //    print("Setting up auth state change listener...")
        //    for await event in self.client.auth.authStateChanges {
        //        let sess = event.session.debugDescription
        //        print("Auth event: \(event.event) - Session: \(sess)")
        //    }
        //    print("Auth state change listener finished.")
        // }
    }
}
