import SwiftUI

struct OnboardingFeedStep: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.themePrimary)
                .padding(.top, 40)

            VStack(spacing: 12) {
                Text("You're All Set!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.themePrimary)

                Text("Start exploring and sharing your music")
                    .font(.body)
                    .foregroundColor(Color.themeSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 16) {
                QuickTipCard(
                    icon: "music.note",
                    title: "Repost Tracks",
                    description: "Share songs, albums, or artists to your feed from any detail page"
                )

                QuickTipCard(
                    icon: "pin.fill",
                    title: "Pin Your Favorites",
                    description: "Show off your top music on your profile"
                )

                QuickTipCard(
                    icon: "chart.bar.fill",
                    title: "Track Your Stats",
                    description: "See detailed analytics about your listening habits"
                )
            }
            .padding(.horizontal, 24)

            if appState.isSpotifyConnected != .istrue {
                VStack(spacing: 12) {
                    Text("Quick Tip")
                        .font(.caption)
                        .foregroundColor(Color.themeSecondary)

                    Text("Connect Spotify to unlock all features")
                        .font(.subheadline)
                        .foregroundColor(Color.themePrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.themeElement)
                        .cornerRadius(8)
                }
                .padding(.top, 8)
            }

            Spacer()
        }
    }
}

struct QuickTipCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color.themePrimary)
                .frame(width: 40, height: 40)
                .background(Color.themeElement)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.themePrimary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(Color.themeSecondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.themeElement)
        .cornerRadius(12)
    }
}
