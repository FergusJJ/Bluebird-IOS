import SwiftUI

struct ArtistStats: View {
    let totalFollowers: Int?
    let userListens: Int?

    @State private var followersOpacity: Double = 0.3
    @State private var listensOpacity: Double = 0.3

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("Total Followers")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.lightGray)
                    .textCase(.uppercase)

                if let followers = totalFollowers {
                    Text(formatNumber(followers))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.nearWhite)
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.lightGray.opacity(0.3))
                        .frame(width: 50, height: 16)
                        .opacity(followersOpacity)
                        .onAppear { animateFollowers() }
                }
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)
                .background(Color.lightGray.opacity(0.3))

            // Listens section
            VStack(spacing: 6) {
                Text("Your Streams")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.lightGray)
                    .textCase(.uppercase)

                if let listens = userListens {
                    Text(formatNumber(listens))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.nearWhite)
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.lightGray.opacity(0.3))
                        .frame(width: 50, height: 16)
                        .opacity(listensOpacity)
                        .onAppear { animateListens() }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.darkElement)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.lightGray.opacity(0.1), lineWidth: 1)
        )
    }

    private func animateFollowers() {
        withAnimation(
            Animation.easeInOut(duration: 1.2)
                .repeatForever(autoreverses: true)
        ) {
            followersOpacity = 1.0
        }
    }

    private func animateListens() {
        withAnimation(
            Animation.easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
        ) {
            listensOpacity = 1.0
        }
    }

    private func formatNumber(_ number: Int) -> String {
        if number >= 1_000_000 {
            let millions = Double(number) / 1_000_000.0
            return String(format: "%.1fm", millions)
        } else if number >= 1000 {
            let thousands = Double(number) / 1000.0
            return String(format: "%.1fk", thousands)
        } else {
            return "\(number)"
        }
    }
}
