import SwiftUI

struct TrendingTrackRowView: View {
    let rank: Int
    let track: SongDetail

    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            Text("#\(rank)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(rankColor)
                .frame(width: 35, alignment: .leading)

            // Album art
            CachedAsyncImage(url: URL(string: track.album_image_url)!)
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 50)
                .cornerRadius(4)

            // Track info
            VStack(alignment: .leading, spacing: 4) {
                Text(track.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundStyle(Color.themePrimary)

                Text(formatArtistNames())
                    .font(.subheadline)
                    .foregroundColor(.themeSecondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var rankColor: Color {
        switch rank {
        case 1:
            return Color.yellow
        case 2:
            return Color.gray
        case 3:
            return Color.orange
        default:
            return Color.themePrimary
        }
    }

    private func formatArtistNames() -> String {
        track.artists.map { $0.name }.joined(separator: ", ")
    }
}
