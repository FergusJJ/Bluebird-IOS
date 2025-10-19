import SwiftUI

struct MilestoneRowView: View {
    let unifiedFeedItem: UnifiedFeedItem
    let currentUserID: String?
    let onEntityTap: () -> Void
    let onProfileTap: () -> Void

    private var isCurrentUser: Bool {
        guard let currentUserID = currentUserID else { return false }
        return unifiedFeedItem.author.user_id == currentUserID
    }

    private var artistName: String {
        if let artist = unifiedFeedItem.artist_detail {
            return artist.name
        }
        return "Artist"
    }

    private var artistImageURL: String? {
        if let artist = unifiedFeedItem.artist_detail {
            return artist.spotify_uri
        }
        return nil
    }

    private var milestoneText: String {
        guard let milestone = unifiedFeedItem.play_count else { return "" }
        let username = isCurrentUser ? "You" : unifiedFeedItem.author.username
        return "\(username) hit \(milestone) plays of \(artistName)"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Profile picture with milestone badge
            Button(action: onProfileTap) {
                ZStack(alignment: .bottomTrailing) {
                    if !unifiedFeedItem.author.avatar_url.isEmpty,
                       let url = URL(string: unifiedFeedItem.author.avatar_url) {
                        CachedAsyncImage(url: url)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .resizable()
                            .padding(8)
                            .foregroundColor(Color.themePrimary)
                            .background(Color.themeBackground.opacity(0.4))
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    }

                    // Trophy badge
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.yellow, Color.orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .offset(x: 4, y: 4)
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Milestone text and artist info
            VStack(alignment: .leading, spacing: 4) {
                Text(milestoneText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.themePrimary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Text(timeAgoString(from: unifiedFeedItem.timestamp))
                        .font(.system(size: 12))
                        .foregroundColor(Color.themeSecondary.opacity(0.8))

                    Text("•")
                        .font(.system(size: 12))
                        .foregroundColor(Color.themeSecondary.opacity(0.5))

                    Button(action: onEntityTap) {
                        Text("View Artist")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.themeAccent)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            Spacer()

            // Small artist thumbnail
            if let imageURL = artistImageURL,
               let url = URL(string: imageURL) {
                Button(action: onEntityTap) {
                    CachedAsyncImage(url: url)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.themePrimary.opacity(0.1), lineWidth: 0.5)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [
                    Color.yellow.opacity(0.08),
                    Color.orange.opacity(0.05),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.yellow.opacity(0.3),
                            Color.orange.opacity(0.2),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func timeAgoString(from date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day, .weekOfYear], from: date, to: now)

        if let week = components.weekOfYear, week > 0 {
            return week == 1 ? "1w" : "\(week)w"
        } else if let day = components.day, day > 0 {
            return day == 1 ? "1d" : "\(day)d"
        } else if let hour = components.hour, hour > 0 {
            return hour == 1 ? "1h" : "\(hour)h"
        } else if let minute = components.minute, minute > 0 {
            return minute == 1 ? "1m" : "\(minute)m"
        } else {
            return "now"
        }
    }
}
