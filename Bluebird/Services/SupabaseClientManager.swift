import Foundation
import Supabase
import UIKit

// TODO: move supabase signup/read calls into this class
class SupabaseClientManager {
    static let shared = SupabaseClientManager()
    let client: SupabaseClient

    private let avatarsPublicBucket = "bluebird-avatars"

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

    // Might change this to only perform upload and move resize stuff but leaving it for now
    func uploadAvatar(avatar: UIImage) async -> Result<String, Error> {
        guard let resized = avatar.resize(to: CGSize(width: 400, height: 400)) else {
            return .failure(NSError(domain: "MyApp", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to resize image."]))
        }

        guard let imageData = resized.jpegData(compressionQuality: 0.8) else {
            return .failure(NSError(domain: "MyApp", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to convert to JPEG."]))
        }

        let fileName = "public/\(UUID().uuidString).jpg"

        do {
            let fileOptions = FileOptions(contentType: "image/jpeg")
            _ = try await client.storage
                .from(avatarsPublicBucket)
                .upload(fileName, data: imageData, options: fileOptions)

            return .success(fileName)

        } catch {
            print("Error: unable to save profile picture to bucket: \(error)")
            return .failure(error)
        }
    }

    func getAvatarUrl(for fileName: String) -> URL? {
        do {
            let avatarUrl = try client.storage
                .from(avatarsPublicBucket)
                .getPublicURL(path: fileName)
            return avatarUrl
        } catch {
            print("Error: unable to get bucket \(error)")
            return nil
        }
    }
}
