import SwiftUI

struct ClickableUserRowView: View {
    let user: UserProfile

    var body: some View {
        HStack(spacing: 16) {
            profileImageContainer
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundStyle(Color.themePrimary)
            }
        }
    }

    private var profileImageContainer: some View {
        Group {
            if user.avatar_url.isEmpty {
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(15)
                    .foregroundColor(Color.themePrimary)
                    .background(Color.themeBackground.opacity(0.4))
            } else {
                CachedAsyncImage(url: URL(string: user.avatar_url)!)
                    .scaledToFit()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            }
        }
    }
}

struct ClickableFriendRequestRowView: View {
    let user: UserProfile
    let onAccept: () -> Void
    let onDeny: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            profileImageContainer
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundStyle(Color.themePrimary)
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: onDeny) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.themeSecondary)  
                }
                Button(action: onAccept) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.themeSecondary)
                }
            }
        }
    }

    private var profileImageContainer: some View {
        Group {
            if user.avatar_url.isEmpty {
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(15)
                    .foregroundColor(Color.themePrimary)
                    .background(Color.themeBackground.opacity(0.4))
            } else {
                CachedAsyncImage(url: URL(string: user.avatar_url)!)
                    .scaledToFit()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            }
        }
    }
}
