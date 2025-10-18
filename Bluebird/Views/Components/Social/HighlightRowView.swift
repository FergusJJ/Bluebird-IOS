import SwiftUI

struct HighlightRowView: View {
    let unifiedFeedItem: UnifiedFeedItem
    let onEntityTap: () -> Void
    let onProfileTap: () -> Void

    private var entityImageURL: String? {
        if let track = unifiedFeedItem.track_detail {
            return track.album_image_url
        } else if let album = unifiedFeedItem.album_detail {
            return album.image_url
        } else if let artist = unifiedFeedItem.artist_detail {
            return artist.spotify_uri
        }
        return nil
    }

    private var entityName: String {
        if let track = unifiedFeedItem.track_detail {
            return track.name
        } else if let album = unifiedFeedItem.album_detail {
            return album.name
        } else if let artist = unifiedFeedItem.artist_detail {
            return artist.name
        }
        return ""
    }

    private var entitySubtext: String {
        if let track = unifiedFeedItem.track_detail {
            return track.artists.map { $0.name }.joined(separator: ", ")
        } else if let album = unifiedFeedItem.album_detail {
            return album.artists.map { $0.name }.joined(separator: ", ")
        }
        return ""
    }

    private var highlightText: String {
        let username = unifiedFeedItem.author.username
        let entityTypeText = unifiedFeedItem.entity_type == "artist" ? "artist" : unifiedFeedItem.entity_type

        switch unifiedFeedItem.content_type {
        case .highlightLoving:
            return "\(username) has been loving this \(entityTypeText)"
        case .highlightDiscovery:
            return "\(username) just discovered this \(entityTypeText)"
        default:
            return ""
        }
    }

    private var highlightIcon: String {
        switch unifiedFeedItem.content_type {
        case .highlightLoving:
            return "heart.fill"
        case .highlightDiscovery:
            return "sparkles"
        default:
            return "star.fill"
        }
    }

    private var highlightColor: Color {
        switch unifiedFeedItem.content_type {
        case .highlightLoving:
            return .pink
        case .highlightDiscovery:
            return .purple
        default:
            return Color.themeAccent
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Highlight header
            Button(action: onProfileTap) {
                HStack(spacing: 8) {
                    ZStack {
                        if !unifiedFeedItem.author.avatar_url.isEmpty,
                           let url = URL(string: unifiedFeedItem.author.avatar_url)
                        {
                            CachedAsyncImage(url: url)
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 24, height: 24)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.fill")
                                .resizable()
                                .padding(5)
                                .foregroundColor(Color.themePrimary)
                                .background(Color.themeBackground.opacity(0.4))
                                .frame(width: 24, height: 24)
                                .clipShape(Circle())
                        }

                        Circle()
                            .stroke(highlightColor, lineWidth: 1.5)
                            .frame(width: 24, height: 24)
                    }

                    Image(systemName: highlightIcon)
                        .font(.caption)
                        .foregroundColor(highlightColor)

                    Text(highlightText)
                        .font(.caption)
                        .foregroundColor(Color.themePrimary)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(
                        colors: [
                            highlightColor.opacity(0.15),
                            highlightColor.opacity(0.05),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            // Entity content
            Button(action: onEntityTap) {
                VStack(alignment: .leading, spacing: 12) {
                    if let imageURL = entityImageURL, let url = URL(string: imageURL) {
                        CachedAsyncImage(url: url)
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: 280)
                            .clipped()
                            .background(Color.themeBackground)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entityName)
                                .font(.headline)
                                .fontWeight(.bold)
                                .lineLimit(2)
                                .foregroundStyle(Color.themePrimary)

                            Text(entitySubtext)
                                .font(.subheadline)
                                .foregroundColor(.themeSecondary)
                                .lineLimit(1)
                        }

                        // Show play count for "loving" highlights
                        if unifiedFeedItem.content_type == .highlightLoving,
                           let playCount = unifiedFeedItem.play_count {
                            HStack(spacing: 4) {
                                Image(systemName: "play.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(highlightColor)
                                Text("\(playCount) plays this week")
                                    .font(.caption)
                                    .foregroundColor(Color.themeSecondary)
                            }
                            .padding(.top, 4)
                        }

                        // Timestamp
                        Text(timeAgoString(from: unifiedFeedItem.timestamp))
                            .font(.caption2)
                            .foregroundColor(Color.themeSecondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .background(Color.themeElement)
        .cornerRadius(12)
    }

    private func timeAgoString(from date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day, .weekOfYear], from: date, to: now)

        if let week = components.weekOfYear, week > 0 {
            return week == 1 ? "1 week ago" : "\(week) weeks ago"
        } else if let day = components.day, day > 0 {
            return day == 1 ? "1 day ago" : "\(day) days ago"
        } else if let hour = components.hour, hour > 0 {
            return hour == 1 ? "1 hour ago" : "\(hour) hours ago"
        } else if let minute = components.minute, minute > 0 {
            return minute == 1 ? "1 minute ago" : "\(minute) minutes ago"
        } else {
            return "Just now"
        }
    }
}
