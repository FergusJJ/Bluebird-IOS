import SwiftUI

struct OnboardingWelcomeStep: View {
    let username: String

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "waveform")
                .font(.system(size: 70))
                .foregroundColor(.themePrimary)
                .padding(.top, 40)

            VStack(spacing: 12) {
                Text("Welcome, \(username)!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color.themePrimary)
                    .multilineTextAlignment(.center)

                Text("Let's get you started with Bluebird")
                    .font(.title3)
                    .foregroundColor(Color.themeSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(alignment: .leading, spacing: 16) {
                FeatureBulletPoint(
                    icon: "chart.bar.fill",
                    text: "Track your listening stats in real-time"
                )
                FeatureBulletPoint(
                    icon: "person.2.fill",
                    text: "Connect with friends and share music"
                )
                FeatureBulletPoint(
                    icon: "music.note.list",
                    text: "Discover what's trending"
                )
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)

            Spacer()
        }
    }
}

struct FeatureBulletPoint: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color.themePrimary)
                .frame(width: 24, height: 24)

            Text(text)
                .font(.body)
                .foregroundColor(Color.themePrimary)
        }
    }
}
