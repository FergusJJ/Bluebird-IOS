import SwiftUI

struct FriendSongRowView: View {
    @State private var breatheScale: CGFloat = 1.0
    @State private var particleOffsets: [CGSize] = []

    let song: SongDetail
    let username: String
    let profilePictureURL: URL?
    let onSongTap: () -> Void
    let onProfileTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Friend header bar with gradient - tappable for profile
            Button(action: onProfileTap) {
                HStack(spacing: 8) {
                    // Profile picture
                    ZStack {
                        if let imageUrl = profilePictureURL {
                            CachedAsyncImage(url: imageUrl)
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

                    Text(username)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.themePrimary)

                    Text("is listening")
                        .font(.caption)
                        .foregroundColor(Color.themeSecondary)

                    Spacer()

                    // Floating music notes particles
                    ZStack {
                        ForEach(0 ..< 3) { index in
                            Image(systemName: "music.note")
                                .font(.caption2)
                                .foregroundColor(Color.themeAccent.opacity(0.6))
                                .offset(particleOffsets.indices.contains(index) ? particleOffsets[index] : .zero)
                                .scaleEffect(breatheScale)
                                .animation(
                                    .easeInOut(duration: 1.5 + Double(index) * 0.3)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(index) * 0.2),
                                    value: breatheScale
                                )
                                .animation(
                                    .easeInOut(duration: 2.0 + Double(index) * 0.5)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(index) * 0.3),
                                    value: particleOffsets
                                )
                        }
                    }
                    .frame(width: 40, height: 20)
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

            // Song content - tappable for song details
            Button(action: onSongTap) {
                HStack(spacing: 12) {
                    CachedAsyncImage(url: URL(string: song.album_image_url)!)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .cornerRadius(4)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(song.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .foregroundStyle(Color.themePrimary)
                        Text(formatArtistNames())
                            .font(.subheadline)
                            .foregroundColor(.themeSecondary)
                            .allowsTightening(true)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .background(Color.themeElement)
        .cornerRadius(8)
        .onAppear {
            breatheScale = 1.2
            particleOffsets = [
                CGSize(width: -5, height: -8),
                CGSize(width: 0, height: -12),
                CGSize(width: 5, height: -8),
            ]
        }
    }

    private func formatArtistNames() -> String {
        song.artists.map { $0.name }.joined(separator: ", ")
    }
}
