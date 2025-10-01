import SwiftUI

struct TopEntityCard: View {
    let imageURL: String
    let name: String
    let playCount: Int
    let isTop: Bool

    var body: some View {
        ZStack(alignment: .bottomLeading) {
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

            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.8),
                    Color.clear,
                ]),
                startPoint: .bottom,
                endPoint: .center
            )
            .cornerRadius(12)

            Text("\(name) - \(playCount) plays")
                .font(isTop ? .title3 : .subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .lineLimit(2)
        }
        .cornerRadius(12)
        .shadow(radius: 3)
    }
}
