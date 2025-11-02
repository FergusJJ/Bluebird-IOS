import SwiftUI

struct ProfileMilestoneRowView: View {
    let milestone: UserMilestone

    var body: some View {
        HStack(spacing: 16) {
            // Artist image
            Group {
                if milestone.artist.spotify_uri.isEmpty {
                    Image(systemName: "music.note")
                        .resizable()
                        .scaledToFit()
                        .padding(15)
                        .foregroundColor(Color.themePrimary)
                        .background(Color.themeBackground.opacity(0.4))
                } else {
                    CachedAsyncImage(url: URL(string: milestone.artist.spotify_uri)!)
                        .scaledToFit()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(milestone.artist.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundStyle(Color.themePrimary)
                Text("\(milestone.milestone) plays")
                    .font(.subheadline)
                    .foregroundColor(.themeSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(formattedTimestamp())
                .font(.caption)
                .foregroundColor(.themeSecondary)
                .frame(width: 45, alignment: .trailing)
        }
    }

    private func formattedTimestamp() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: milestone.unlocked_at, relativeTo: Date())
    }
}
