import SwiftUI

struct TopEntityCard: View {
    let imageURL: String
    let name: String
    let playCount: Int
    let isTop: Bool
    let badgeText: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background Image
            if let url = URL(string: imageURL) {
                CachedAsyncImage(url: url)
                    .aspectRatio(contentMode: .fill)
                    .frame(height: isTop ? 220 : 140)
                    .clipped()
                    .cornerRadius(12)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: isTop ? 220 : 140)
                    .cornerRadius(12)
            }

            // Gradient overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.8),
                    Color.clear,
                ]),
                startPoint: .bottom,
                endPoint: .center
            )
            .cornerRadius(12)

            // Top left badge
            if isTop {
                HStack {
                    Text(badgeText)
                        .font(.system(size: 14, weight: .semibold))
                    Image(systemName: "star")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.nearWhite)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.darkBackground.opacity(0.8))
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.nearWhite.opacity(0.4), lineWidth: 0.3)
                )
                .padding(.top, 12)
                .padding(.leading, 12)
            }

            // Bottom section with artist name and play count
            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    // Artist name - bottom left
                    Text(name)
                        .font(isTop ? .title3 : .subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(2)

                    Spacer()

                    // Play count - bottom right
                    Text("\(playCount) plays")
                        .font(.system(size: isTop ? 16 : 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
        }
        .frame(height: isTop ? 220 : 140)
        .cornerRadius(12)
        .shadow(radius: 3)
    }
}
