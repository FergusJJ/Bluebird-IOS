import SwiftUI

struct MilestonesPreviewView: View {
    let milestones: [UserMilestone]
    let onTap: () -> Void

    private let maxVisible = 3
    private let imageSize: CGFloat = 32
    private let overlapOffset: CGFloat = 20

    var body: some View {
        if !milestones.isEmpty {
            Button(action: onTap) {
                HStack(spacing: 4) {
                    ZStack(alignment: .leading) {
                        ForEach(Array(milestones.prefix(maxVisible).enumerated()), id: \.offset) { index, milestone in
                            ArtistImageView(
                                imageURL: milestone.artist.spotify_uri,
                                size: imageSize
                            )
                            .offset(x: CGFloat(index) * overlapOffset)
                            .zIndex(Double(maxVisible - index))
                        }
                    }
                    .frame(width: CGFloat(min(milestones.count, maxVisible) - 1) * overlapOffset + imageSize)

                    Text(milestoneText)
                        .font(.subheadline)
                        .foregroundColor(Color.themeSecondary)
                        .padding(.leading, 4)
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private var milestoneText: String {
        let count = milestones.count
        if count == 1 {
            return "1 milestone unlocked"
        } else if count <= maxVisible {
            return "\(count) milestones unlocked"
        } else {
            return "\(maxVisible) milestones + \(count - maxVisible) more"
        }
    }
}

struct ArtistImageView: View {
    let imageURL: String
    let size: CGFloat

    var body: some View {
        Group {
            if imageURL.isEmpty {
                Circle()
                    .fill(Color.themeElement)
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: "music.note")
                            .resizable()
                            .scaledToFit()
                            .padding(size * 0.3)
                            .foregroundColor(Color.themeSecondary)
                    )
            } else {
                CachedAsyncImage(url: URL(string: imageURL)!)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            }
        }
        .overlay(
            Circle()
                .stroke(Color.themeAccent.opacity(0.5), lineWidth: 2)
        )
    }
}
