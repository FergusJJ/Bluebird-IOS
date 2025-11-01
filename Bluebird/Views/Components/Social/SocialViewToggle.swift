import SwiftUI

enum SocialViewType: Hashable {
    case feed
    case trending
}

struct SocialViewToggle: View {
    @Binding var selectedView: SocialViewType

    var body: some View {
        HStack(spacing: 0) {
            Button(action: { selectedView = .feed }) {
                Text("Feed")
                    .font(.subheadline)
                    .fontWeight(selectedView == .feed ? .semibold : .regular)
                    .foregroundColor(selectedView == .feed ? Color.themePrimary : Color.themeSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        selectedView == .feed ? Color.themeElement : Color.clear
                    )
            }
            .buttonStyle(PlainButtonStyle())

            Divider()
                .background(Color.themeSecondary.opacity(0.3))

            Button(action: { selectedView = .trending }) {
                Text("Trending")
                    .font(.subheadline)
                    .fontWeight(selectedView == .trending ? .semibold : .regular)
                    .foregroundColor(selectedView == .trending ? Color.themePrimary : Color.themeSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        selectedView == .trending ? Color.themeElement : Color.clear
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(height: 36)
        .background(Color.themeBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.themeSecondary.opacity(0.2), lineWidth: 1)
        )
    }
}
