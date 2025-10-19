import SwiftUI

struct FeedPostRowView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel

    let feedPost: FeedPostItem
    let currentUserID: String?
    let onEntityTap: () -> Void
    let onProfileTap: () -> Void
    let onDeleteTap: () -> Void

    private var isCurrentUser: Bool {
        guard let currentUserID = currentUserID else { return false }
        return feedPost.post.author.user_id == currentUserID
    }

    private var entityImageURL: String? {
        if let track = feedPost.track_detail {
            return track.album_image_url
        } else if let album = feedPost.album_detail {
            return album.image_url
        } else if let artist = feedPost.artist_detail {
            return artist.spotify_uri
        }
        return nil
    }

    private var entityName: String {
        if let track = feedPost.track_detail {
            return track.name
        } else if let album = feedPost.album_detail {
            return album.name
        } else if let artist = feedPost.artist_detail {
            return artist.name
        }
        return ""
    }

    private var entitySubtext: String {
        if let track = feedPost.track_detail {
            return track.artists.map { $0.name }.joined(separator: ", ")
        } else if let album = feedPost.album_detail {
            return album.artists.map { $0.name }.joined(separator: ", ")
        } /*else if let artist = feedPost.artist_detail {
            return "Artist"
        }*/
        return ""
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onProfileTap) {
                HStack(spacing: 10) {
                    ZStack {
                        if !feedPost.post.author.avatar_url.isEmpty,
                           let url = URL(string: feedPost.post.author.avatar_url)
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

                    Text(isCurrentUser ? "You" : feedPost.post.author.username)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.themePrimary)

                    Text("reposted")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.themeSecondary)

                    Spacer()

                    if isCurrentUser {
                        Button(action: onDeleteTap) {
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
                    if let imageURL = entityImageURL, let url = URL(string: imageURL) {
                        GeometryReader { geometry in
                            CachedAsyncImage(url: url)
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 300)
                        .background(Color.themeBackground)
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

                        if !feedPost.post.caption.isEmpty {
                            Text(feedPost.post.caption)
                                .font(.system(size: 15))
                                .foregroundColor(Color.themePrimary)
                                .lineLimit(4)
                                .padding(.top, 4)
                        }

                        HStack(spacing: 16) {
                            HStack(spacing: 5) {
                                Image(systemName: feedPost.post.user_has_liked ? "heart.fill" : "heart")
                                    .font(.system(size: 13))
                                    .foregroundColor(feedPost.post.user_has_liked ? .red : Color.themeSecondary)
                                Text("\(feedPost.post.likes_count)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.themeSecondary)
                            }

                            HStack(spacing: 5) {
                                Image(systemName: "bubble.right")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.themeSecondary)
                                Text("\(feedPost.post.comments_count)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.themeSecondary)
                            }

                            Spacer()

                            Text(timeAgoString(from: feedPost.post.created_at))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.themeSecondary.opacity(0.8))
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
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.themeElement)

                // Subtle inner highlight
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.themeHighlight.opacity(0.6),
                                Color.clear,
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.themePrimary.opacity(0.08), lineWidth: 0.5)
        )
        .shadow(color: Color.themeShadow, radius: 3, x: 0, y: 3)
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
