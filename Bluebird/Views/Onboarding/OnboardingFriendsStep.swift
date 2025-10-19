import SwiftUI

struct OnboardingFriendsStep: View {
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundColor(.themeAccent)
                .padding(.top, 40)

            VStack(spacing: 12) {
                Text("Connect with Friends")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.themeAccent)

                Text("Share your music journey with others")
                    .font(.body)
                    .foregroundColor(Color.themeSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 20) {
                InstructionCard(
                    number: "1",
                    title: "Search for Friends",
                    description: "Tap the search icon in the Social tab to find users"
                )

                InstructionCard(
                    number: "2",
                    title: "Send Requests",
                    description: "Connect with friends to see their music activity"
                )

                InstructionCard(
                    number: "3",
                    title: "See What's Playing",
                    description: "Check out the 'Now Playing' tab to see what friends are listening to right now"
                )
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}

struct InstructionCard: View {
    let number: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(number)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.themePrimary)
                .frame(width: 32, height: 32)
                .background(Color.themeElement)
                .clipShape(Circle())

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
    }
}
