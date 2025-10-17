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
                HStack(spacing: 8) {
                    ZStack {
                        if !feedPost.post.author.avatar_url.isEmpty,
                           let url = URL(string: feedPost.post.author.avatar_url)
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
                            .stroke(Color.themeAccent, lineWidth: 1.5)
                            .frame(width: 24, height: 24)
                    }

                    Text(isCurrentUser ? "You" : feedPost.post.author.username)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.themePrimary)

                    Text("reposted")
                        .font(.caption)
                        .foregroundColor(Color.themeSecondary)

                    Spacer()

                    if isCurrentUser {
                        Button(action: onDeleteTap) {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundColor(Color.themeSecondary)
                                .padding(6)
                                .background(Color.themeBackground.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(
                        colors: [
                            Color.themeAccent.opacity(0.15),
                            Color.themeAccent.opacity(0.05),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

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

                        if !feedPost.post.caption.isEmpty {
                            Text(feedPost.post.caption)
                                .font(.subheadline)
                                .foregroundColor(Color.themePrimary)
                                .lineLimit(4)
                                .padding(.top, 4)
                        }

                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: feedPost.post.user_has_liked ? "heart.fill" : "heart")
                                    .font(.caption)
                                    .foregroundColor(feedPost.post.user_has_liked ? .red : Color.themeSecondary)
                                Text("\(feedPost.post.likes_count)")
                                    .font(.caption)
                                    .foregroundColor(Color.themeSecondary)
                            }

                            HStack(spacing: 4) {
                                Image(systemName: "bubble.right")
                                    .font(.caption)
                                    .foregroundColor(Color.themeSecondary)
                                Text("\(feedPost.post.comments_count)")
                                    .font(.caption)
                                    .foregroundColor(Color.themeSecondary)
                            }

                            Spacer()

                            Text(timeAgoString(from: feedPost.post.created_at))
                                .font(.caption2)
                                .foregroundColor(Color.themeSecondary)
                        }
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
