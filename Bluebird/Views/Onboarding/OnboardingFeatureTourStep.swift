import SwiftUI

struct OnboardingFeatureTourStep: View {
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 60))
                .foregroundColor(.themeAccent)
                .padding(.top, 40)

            VStack(spacing: 12) {
                Text("Explore Your Tabs")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.themeAccent)

                Text("Navigate through four main sections")
                    .font(.body)
                    .foregroundColor(Color.themeSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 20) {
                TabFeatureCard(
                    icon: "music.note.house.fill",
                    title: "Social",
                    description: "See what your friends are listening to"
                )

                TabFeatureCard(
                    icon: "music.note.list",
                    title: "History",
                    description: "View your complete listening history"
                )

                TabFeatureCard(
                    icon: "chart.pie",
                    title: "Stats",
                    description: "Dive deep into your music analytics"
                )

                TabFeatureCard(
                    icon: "person.crop.circle",
                    title: "Profile",
                    description: "Customize your profile and pins"
                )
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}

struct TabFeatureCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color.themePrimary)
                .frame(width: 40, height: 40)
                .background(Color.themeElement)
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color.themePrimary)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(Color.themeSecondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.themeElement)
        .cornerRadius(12)
    }
}
