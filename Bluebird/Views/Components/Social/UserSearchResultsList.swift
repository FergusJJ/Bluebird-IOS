import SwiftUI

struct UserSearchResultsList: View {
    @EnvironmentObject var searchViewModel: GenericSearchViewModel<UserProfile, SearchUserResult>

    var body: some View {
        List {
            ForEach(searchViewModel.searchResults) { result in
                NavigationLink(destination: UserProfileView(userProfile: result)) {
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
}
