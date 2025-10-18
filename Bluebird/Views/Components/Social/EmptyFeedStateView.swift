import SwiftUI

struct EmptyFeedStateView: View {
    let onFindFriends: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(Color.themePrimary.opacity(0.5))

            // Title and description
            VStack(spacing: 12) {
                Text("Your Feed is Quiet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.themePrimary)

                Text("Connect with friends to see what they're listening to")
                    .font(.body)
                    .foregroundColor(Color.themePrimary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // CTAs
            VStack(spacing: 12) {
                Button(action: onFindFriends) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 16))
                        Text("Find Friends")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.themeAccent)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 48)

                Text("Share your favorite tracks from the History or Stats tabs")
                    .font(.caption)
                    .foregroundColor(Color.themePrimary.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 48)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.themeBackground)
    }
}
