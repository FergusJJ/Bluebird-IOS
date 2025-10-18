import SwiftUI

struct EmptyNowPlayingStateView: View {
    let onFindFriends: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "person.2.wave.2")
                .font(.system(size: 60))
                .foregroundColor(Color.themePrimary.opacity(0.5))

            // Title and description
            VStack(spacing: 12) {
                Text("No Friends Listening")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.themePrimary)

                Text("None of your friends are listening to music right now")
                    .font(.body)
                    .foregroundColor(Color.themePrimary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // CTA
            Button(action: onFindFriends) {
                HStack {
                    Image(systemName: "person.crop.badge.magnifyingglass")
                        .font(.system(size: 16))
                    Text("Find More Friends")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.themeAccent)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal, 48)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.themeBackground)
    }
}
