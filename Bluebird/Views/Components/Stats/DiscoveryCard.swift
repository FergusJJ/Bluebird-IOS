import SwiftUI

struct DiscoveredEntityCard: View {
    let imageURL: String?
    let name: String
    let playCount: Int
    let isTop: Bool
    let badgeText: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: imageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: isTop ? 180 : 85, height: isTop ? 180 : 85)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if !badgeText.isEmpty {
                    Text(badgeText)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.purple.opacity(0.9))
                        )
                        .padding(8)
                }

                // "New" badge indicator
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(.yellow)
                    .padding(6)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.6))
                    )
                    .padding(isTop ? 8 : 6)
            }

            VStack(spacing: 2) {
                Text(name)
                    .font(isTop ? .subheadline : .caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.themePrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Text("\(playCount) plays")
                    .font(.caption2)
                    .foregroundColor(Color.themePrimary.opacity(0.7))
            }
            .frame(width: isTop ? 180 : 85)
        }
        .frame(maxWidth: .infinity)
    }
}
