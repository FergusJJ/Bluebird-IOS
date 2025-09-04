import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    // may want to add stuff here for all time song plays/number of artists listened to etc.
    // but not sure how/where im going to store that yet

    @Published var username: String = ""
    @Published var bio: String = ""
    @Published var avatarPath = ""
    @Published var avatarURL: URL?
    @Published var selectedImage: UIImage?

    @Published var isLoading = false

    private var appState: AppState

    private let bluebirdAccountAPIService: BluebirdAccountAPIService
    private let supabaseManager = SupabaseClientManager.shared

    init(appState: AppState, bluebirdAccountAPIService: BluebirdAccountAPIService) {
        self.appState = appState
        self.bluebirdAccountAPIService = bluebirdAccountAPIService
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

    func updateUserBio(with bio: String) async -> Bool {
        if isLoading {
            return false
        }
        let oldBio = self.bio
        self.bio = bio

        let success = await updateProfile(username: nil, bio: bio, avatarPath: nil)
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
                    print("A Supabase-specific error occurred: \(presentationError.localizedDescription)")
                    appState.setError(presentationError)
                } else {
                    print("A generic error occurred: \(error.localizedDescription)")
                    let presentationError = AppError.genericSupabaseError
                    appState.setError(presentationError)
                }
            }
            avatarURL = oldAvatarURL
            return false
        }

        let updateSuccess = await updateProfile(username: nil, bio: nil, avatarPath: fileName)
        if updateSuccess {
            avatarURL = supabaseManager.getAvatarUrl(for: fileName)
            return true
        } else {
            // TODO: Add logic to delete orphaned avatar URL?
            avatarURL = oldAvatarURL
            return false
        }
    }

    private func updateProfile(username: String?, bio: String?, avatarPath: String?) async -> Bool {
        guard username != nil || bio != nil || avatarPath != nil else {
            print("Error: At least one profile attribute must be provided.")
            return false
        }
        let result = await bluebirdAccountAPIService.updateProfile(username: username, bio: bio, avatarPath: avatarPath)
        switch result {
        case .success():
            print("Successfully update profile info!")
            return true
        // probably want some ui feedback here like a popup
        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("An API error occurred: \(presentationError.localizedDescription)")
            appState.setError(presentationError)
            return false
        }
    }
}
