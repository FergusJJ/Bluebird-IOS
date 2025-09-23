import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    // may want to add stuff here for all time song plays/number of artists listened to etc.
    // but not sure how/where im going to store that yet

    // MARK: User profile vars

    @Published var username: String = ""
    @Published var bio: String = ""
    @Published var avatarPath = ""
    @Published var avatarURL: URL?
    @Published var selectedImage: UIImage?

    // MARK: User stats vars

    @Published var totalMinutesListened: Int = 0
    @Published var totalPlays: Int = 0
    @Published var totalUniqueArtists: Int = 0

    // MARK: extra

    @Published var searchQuery: String = ""

    @Published var isLoading = false

    @Published var pinnedArtists: [ScrollViewObject] = [
        ScrollViewObject(
            imageURL:
            URL(
                string:
                "https://i.scdn.co/image/ab67616d0000b2734d070fdf58fad8c54c5beb85"
            )!,
            name: "Artist 1"
        ),
        ScrollViewObject(
            imageURL: URL(
                string:
                "https://i.scdn.co/image/ab67616d0000b2734d070fdf58fad8c54c5beb85"
            )!,
            name: "Artist 2"
        ),
        ScrollViewObject(
            imageURL: URL(
                string:
                "https://i.scdn.co/image/ab67616d0000b2734d070fdf58fad8c54c5beb85"
            )!,
            name: "Artist 3"
        ),
        ScrollViewObject(
            imageURL: URL(
                string:
                "https://i.scdn.co/image/ab67616d0000b2734d070fdf58fad8c54c5beb85"
            )!,
            name: "Artist 4"
        ),
        ScrollViewObject(
            imageURL: URL(
                string:
                "https://i.scdn.co/image/ab67616d0000b2734d070fdf58fad8c54c5beb85"
            )!,
            name: "Artist 5"
        ),
    ]

    @Published var pinnedTracks: [ScrollViewObject] = [
        ScrollViewObject(
            imageURL:
            URL(
                string:
                "https://i.scdn.co/image/ab67616d0000b2734d070fdf58fad8c54c5beb85"
            )!,
            name: "track 1"
        ),
        ScrollViewObject(
            imageURL: URL(
                string:
                "https://i.scdn.co/image/ab67616d0000b2734d070fdf58fad8c54c5beb85"
            )!,
            name: "track 1"
        ),
        ScrollViewObject(
            imageURL: URL(
                string:
                "https://i.scdn.co/image/ab67616d0000b2734d070fdf58fad8c54c5beb85"
            )!,
            name: "track 1"
        ),
        ScrollViewObject(
            imageURL: URL(
                string:
                "https://i.scdn.co/image/ab67616d0000b2734d070fdf58fad8c54c5beb85"
            )!,
            name: "track 1"
        ),
        ScrollViewObject(
            imageURL: URL(
                string:
                "https://i.scdn.co/image/ab67616d0000b2734d070fdf58fad8c54c5beb85"
            )!,
            name: "track 1"
        ),
    ]

    @Published var pinnedAlbums: [ScrollViewObject] = [
        ScrollViewObject(
            imageURL:
            URL(
                string:
                "https://i.scdn.co/image/ab67616d0000b2734d070fdf58fad8c54c5beb85"
            )!,
            name: "Album 1"
        ),
        ScrollViewObject(
            imageURL: URL(
                string:
                "https://i.scdn.co/image/ab67616d0000b2734d070fdf58fad8c54c5beb85"
            )!,
            name: "Album 2"
        ),
        ScrollViewObject(
            imageURL: URL(
                string:
                "https://i.scdn.co/image/ab67616d0000b2734d070fdf58fad8c54c5beb85"
            )!,
            name: "Album 3"
        ),
        ScrollViewObject(
            imageURL: URL(
                string:
                "https://i.scdn.co/image/ab67616d0000b2734d070fdf58fad8c54c5beb85"
            )!,
            name: "Album 4"
        ),
        ScrollViewObject(
            imageURL: URL(
                string:
                "https://i.scdn.co/image/ab67616d0000b2734d070fdf58fad8c54c5beb85"
            )!,
            name: "Album 5"
        ),
    ]

    private var appState: AppState

    private let bluebirdAccountAPIService: BluebirdAccountAPIService
    private let supabaseManager = SupabaseClientManager.shared

    init(
        appState: AppState,
        bluebirdAccountAPIService: BluebirdAccountAPIService
    ) {
        self.appState = appState
        self.bluebirdAccountAPIService = bluebirdAccountAPIService
    }

    func getCurrentlyPlayingHeadline() -> String {
        return "\(appState.currentSong) - \(appState.currentArtist)"
    }

    func loadProfile() async {
        let result = await bluebirdAccountAPIService.getProfile()
        switch result {
        case let .success(profileInfo):
            username = profileInfo.username
            bio = profileInfo.bio
            avatarURL = URL(string: profileInfo.avatarUrl)
        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error loading profile info: \(presentationError)")
        }
    }

    func loadHeadlineStats() async {
        let result = await bluebirdAccountAPIService.getHeadlineStats()
        switch result {
        case let .success(stats):
            totalPlays = stats.total_plays
            totalUniqueArtists = stats.unique_artists
            totalMinutesListened = (stats.total_duration_millis / (60 * 1000))
        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error loading headline stats info: \(presentationError)")
        }
    }

    func updateUserBio(with bio: String) async -> Bool {
        if isLoading {
            return false
        }
        let oldBio = self.bio
        self.bio = bio

        let success = await updateProfile(
            username: nil,
            bio: bio,
            avatarPath: nil
        )
        if !success {
            self.bio = oldBio
        }
        return success
    }

    // TODO: to think about/add deletions too, so maybe UIImage should be optional
    func updateProfilePicture(with image: UIImage) async -> Bool {
        if isLoading {
            return false
        }

        isLoading = true
        selectedImage = image
        let oldAvatarURL = avatarURL
        defer {
            isLoading = false
            selectedImage = nil
        }

        let result = await supabaseManager.uploadAvatar(avatar: image)

        guard case let .success(fileName) = result else {
            if case let .failure(error) = result {
                if let supabaseError = error as? SupabaseError {
                    let presentationError = AppError(from: supabaseError)
                    print(
                        "A Supabase-specific error occurred: \(presentationError.localizedDescription)"
                    )
                    appState.setError(presentationError)
                } else {
                    print(
                        "A generic error occurred: \(error.localizedDescription)"
                    )
                    let presentationError = AppError.genericSupabaseError
                    appState.setError(presentationError)
                }
            }
            avatarURL = oldAvatarURL
            return false
        }

        let updateSuccess = await updateProfile(
            username: nil,
            bio: nil,
            avatarPath: fileName
        )
        if updateSuccess {
            avatarURL = supabaseManager.getAvatarUrl(for: fileName)
            return true
        } else {
            // TODO: Add logic to delete orphaned avatar URL?
            avatarURL = oldAvatarURL
            return false
        }
    }

    private func updateProfile(
        username: String?,
        bio: String?,
        avatarPath: String?
    ) async -> Bool {
        guard username != nil || bio != nil || avatarPath != nil else {
            print("Error: At least one profile attribute must be provided.")
            return false
        }
        let result = await bluebirdAccountAPIService.updateProfile(
            username: username,
            bio: bio,
            avatarPath: avatarPath
        )
        switch result {
        case .success():
            print("Successfully update profile info!")
            return true
        // probably want some ui feedback here like a popup
        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print(
                "An API error occurred: \(presentationError.localizedDescription)"
            )
            appState.setError(presentationError)
            return false
        }
    }
}
