import SwiftUI

struct RepostRowView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel

    let repostItem: RepostItem
    let isCurrentUser: Bool
    let onEntityTap: () -> Void
    let onProfileTap: () -> Void
    let onUnrepostTap: () -> Void

    private var entityImageURL: String? {
        if let track = repostItem.track_detail {
            return track.album_image_url
        } else if let album = repostItem.album_detail {
            return album.image_url
        } else if let artist = repostItem.artist_detail {
            return artist.spotify_uri
        }
        return nil
    }

    private var entityName: String {
        if let track = repostItem.track_detail {
            return track.name
        } else if let album = repostItem.album_detail {
            return album.name
        } else if let artist = repostItem.artist_detail {
            return artist.name
        }
        return ""
    }

    private var entitySubtext: String {
        if let track = repostItem.track_detail {
            return track.artists.map { $0.name }.joined(separator: ", ")
        } else if let album = repostItem.album_detail {
            return album.artists.map { $0.name }.joined(separator: ", ")
        }
        /*else if let artist = repostItem.artist_detail {
            return "Artist"
        }*/
        return ""
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onProfileTap) {
                HStack(spacing: 10) {
                    ZStack {
                        if !repostItem.repost.profile.avatar_url.isEmpty,
                           let url = URL(string: repostItem.repost.profile.avatar_url)
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

                    Text(isCurrentUser ? "You" : repostItem.repost.profile.username)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.themePrimary)

                    Text("reposted")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.themeSecondary)

                    Spacer()

                    if isCurrentUser {
                        Button(action: onUnrepostTap) {
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

                        if !repostItem.repost.caption.isEmpty {
                            Text(repostItem.repost.caption)
                                .font(.system(size: 15))
                                .foregroundColor(Color.themePrimary)
                                .lineLimit(3)
                                .padding(.top, 4)
                        }

                        HStack(spacing: 16) {
                            HStack(spacing: 5) {
                                Image(systemName: repostItem.repost.user_has_liked ? "heart.fill" : "heart")
                                    .font(.system(size: 13))
                                    .foregroundColor(repostItem.repost.user_has_liked ? .red : Color.themeSecondary)
                                Text("\(repostItem.repost.likes_count)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.themeSecondary)
                            }

                            HStack(spacing: 5) {
                                Image(systemName: "bubble.right")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.themeSecondary)
                                Text("\(repostItem.repost.comments_count)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.themeSecondary)
                            }

                            Spacer()

                            Text(timeAgoString(from: repostItem.repost.created_at))
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
