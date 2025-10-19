import SwiftUI

struct UserSearchResultsList: View {
    @EnvironmentObject var searchViewModel: GenericSearchViewModel<UserProfile, SearchUserResult>

    private var currentUserID: String? {
        CacheManager.shared.getCurrentUserId()
    }

    var body: some View {
        List {
            ForEach(searchViewModel.searchResults) { result in
                NavigationLink(destination: profileDestination(for: result)) {
                    ClickableUserRowView(user: result)
                }
                .listRowBackground(Color.themeElement)
            }
            if searchViewModel.isSearching {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.themeBackground)
    }

    @ViewBuilder
    private func profileDestination(for profile: UserProfile) -> some View {
        if let currentUserID = currentUserID,
           profile.user_id.lowercased() == currentUserID.lowercased() {
            ProfileViewV2()
        } else {
            UserProfileView(userProfile: profile)
        }
    }
}
