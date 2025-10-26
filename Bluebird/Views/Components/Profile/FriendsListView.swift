import SwiftUI

struct FriendsListView: View {

    @EnvironmentObject var socialViewModel: SocialViewModel

    let initialFriends: [UserProfile]
    let username: String
    let isRequests: Bool

    @State private var friends: [UserProfile]

    init(friends: [UserProfile], username: String, isRequests: Bool) {
        self.initialFriends = friends
        self.username = username
        self.isRequests = isRequests
        self._friends = State(initialValue: friends)
    }

    private var currentUserID: String? {
        CacheManager.shared.getCurrentUserId()
    }

    var body: some View {
        List {
            ForEach(friends) { friend in
                if isRequests {
                    ClickableFriendRequestRowView(
                        user: friend,
                        onAccept: {
                            Task {
                                await socialViewModel.respondToFriendRequests(
                                    to: friend.user_id,
                                    accept: true
                                )
                                friends.removeAll {
                                    $0.user_id == friend.user_id
                                }
                            }
                        },
                        onDeny: {
                            Task {
                                await socialViewModel.respondToFriendRequests(
                                    to: friend.user_id,
                                    accept: false
                                )
                                friends.removeAll { $0.user_id == friend.user_id }
                            }
                        }
                    )
                    .listRowBackground(Color.themeElement)
                } else {
                    NavigationLink(destination: profileDestination(for: friend))
                    {
                        ClickableUserRowView(user: friend)
                    }
                    .listRowBackground(Color.themeElement)
                }
            }

            if friends.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 40))
                        .foregroundColor(Color.themeSecondary)
                    Text(isRequests ? "No requests" : "No friends yet")
                        .font(.headline)
                        .foregroundColor(Color.themePrimary)
                    Text(
                        isRequests
                            ? "No incoming friend requests"
                            : "Add friends to see them here"
                    )
                    .font(.subheadline)
                    .foregroundColor(Color.themeSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
                .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.themeBackground)
        .navigationTitle(
            isRequests ? "Friend requests" : "\(username)'s Friends"
        )
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func profileDestination(for profile: UserProfile) -> some View {
        if let currentUserID = currentUserID,
            profile.user_id.lowercased() == currentUserID.lowercased()
        {
            ProfileViewV2()
        } else {
            UserProfileView(userProfile: profile)
        }
    }
}
