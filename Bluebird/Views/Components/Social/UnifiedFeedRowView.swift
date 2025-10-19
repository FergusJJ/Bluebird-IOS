import SwiftUI

struct UnifiedFeedRowView: View {
    let unifiedFeedItem: UnifiedFeedItem
    let currentUserID: String?
    let onEntityTap: () -> Void
    let onProfileTap: () -> Void
    let onDeleteTap: (() -> Void)?

    var body: some View {
        switch unifiedFeedItem.content_type {
        case .repost:
            RepostInUnifiedFeedView(
                unifiedFeedItem: unifiedFeedItem,
                currentUserID: currentUserID,
                onEntityTap: onEntityTap,
                onProfileTap: onProfileTap,
                onDeleteTap: onDeleteTap
            )

        case .highlightLoving, .highlightDiscovery:
            HighlightRowView(
                unifiedFeedItem: unifiedFeedItem,
                onEntityTap: onEntityTap,
                onProfileTap: onProfileTap
            )

        case .highlightMilestone:
            MilestoneRowView(
                unifiedFeedItem: unifiedFeedItem,
                currentUserID: currentUserID,
                onEntityTap: onEntityTap,
                onProfileTap: onProfileTap
            )
        }
    }
}

struct RepostInUnifiedFeedView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel

    let unifiedFeedItem: UnifiedFeedItem
    let currentUserID: String?
    let onEntityTap: () -> Void
    let onProfileTap: () -> Void
    let onDeleteTap: (() -> Void)?

    private var isCurrentUser: Bool {
        guard let currentUserID = currentUserID else { return false }
        return unifiedFeedItem.author.user_id == currentUserID
    }

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

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onProfileTap) {
                HStack(spacing: 10) {
                    ZStack {
                        if !unifiedFeedItem.author.avatar_url.isEmpty,
                            let url = URL(
                                string: unifiedFeedItem.author.avatar_url
                            )
                        {
                            CachedAsyncImage(url: url)
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 28, height: 28)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.fill")
                                .resizable()
                                .padding(6)
                                .foregroundColor(Color.themePrimary)
                                .background(Color.themeBackground.opacity(0.4))
                                .frame(width: 28, height: 28)
                                .clipShape(Circle())
                        }

                        Circle()
                            .stroke(Color.themeAccent, lineWidth: 2)
                            .frame(width: 28, height: 28)
                    }

                    Text(
                        isCurrentUser ? "You" : unifiedFeedItem.author.username
                    )
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.themePrimary)

                    Text("reposted")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.themeSecondary)

                    Spacer()

                    if isCurrentUser, let onDelete = onDeleteTap {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 13))
                                .foregroundColor(Color.themeSecondary)
                                .padding(8)
                                .background(Color.themeBackground.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [
                            Color.themeAccent.opacity(0.12),
                            Color.themeAccent.opacity(0.04),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: onEntityTap) {
                VStack(alignment: .leading, spacing: 0) {
                    if let imageURL = entityImageURL,
                        let url = URL(string: imageURL)
                    {
                        GeometryReader { geometry in
                            ZStack(alignment: .bottom) {
                                CachedAsyncImage(url: url)
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .clipped()

                                // Subtle bottom gradient for depth
                                LinearGradient(
                                    colors: [Color.clear, Color.black.opacity(0.15)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 280)
                        .background(Color.themeBackground)
                        .cornerRadius(8)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(entityName)
                                .font(.system(size: 18, weight: .bold))
                                .lineLimit(2)
                                .foregroundStyle(Color.themePrimary)

                            Text(entitySubtext)
                                .font(.system(size: 15))
                                .foregroundColor(.themeSecondary)
                                .lineLimit(1)
                        }

                        if let caption = unifiedFeedItem.caption,
                            !caption.isEmpty
                        {
                            Text(caption)
                                .font(.system(size: 15))
                                .foregroundColor(Color.themePrimary)
                                .lineLimit(3)
                                .padding(.top, 4)
                        }

                        HStack(spacing: 16) {
                            if let likesCount = unifiedFeedItem.likes_count,
                                let userHasLiked = unifiedFeedItem
                                    .user_has_liked
                            {
                                HStack(spacing: 5) {
                                    Image(
                                        systemName: userHasLiked
                                            ? "heart.fill" : "heart"
                                    )
                                    .font(.system(size: 13))
                                    .foregroundColor(
                                        userHasLiked
                                            ? .red : Color.themeSecondary
                                    )
                                    Text("\(likesCount)")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Color.themeSecondary)
                                }
                            }

                            if let commentsCount = unifiedFeedItem
                                .comments_count
                            {
                                HStack(spacing: 5) {
                                    Image(systemName: "bubble.right")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color.themeSecondary)
                                    Text("\(commentsCount)")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Color.themeSecondary)
                                }
                            }

                            Spacer()

                            Text(timeAgoString(from: unifiedFeedItem.timestamp))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.themeSecondary.opacity(0.6))
                        }
                        .padding(.top, 2)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 14)
                    .padding(.bottom, 14)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.themeElement.opacity(0.4))
                .overlay(
                    VStack {
                        LinearGradient(
                            colors: [Color.themeHighlight, Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        ).cornerRadius(16)
                    })
                .shadow(color: .themeShadow, radius: 4, x: 0, y: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.themeAccent.opacity(0.2), lineWidth: 1)
        )
    }

    private func timeAgoString(from date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents(
            [.minute, .hour, .day, .weekOfYear],
            from: date,
            to: now
        )

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
