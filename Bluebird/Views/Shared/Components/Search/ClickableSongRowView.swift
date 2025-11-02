import SwiftUI

// similar to SongRowView, should look the same
struct ClickableSongRowView: View {
    @State private var animationTrigger = 0

    let song: SongDetail
    let isInHistory: Bool
    let isPlaying: Bool

    var body: some View {
        HStack(spacing: 16) {
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
            if isInHistory {
                Spacer()

                if isPlaying {
                    Image(systemName: "waveform")
                        .symbolEffect(
                            .bounce,
                            options: .speed(0.5),
                            value: animationTrigger
                        )
                        .frame(width: 45, alignment: .trailing)
                        .font(.subheadline)
                        .foregroundStyle(Color.themeAccent)
                        .onAppear {
                            Timer.scheduledTimer(
                                withTimeInterval: 0.5,
                                repeats: true
                            ) { _ in
                                animationTrigger += 1
                            }
                        }
                } else {
                    Text(formattedTimestamp())
                        .font(.caption)
                        .foregroundColor(.themeSecondary)
                        .frame(width: 45, alignment: .trailing)
                }
            }
        }
    }

    private func formatArtistNames() -> String {
        song.artists.map { $0.name }.joined(separator: ", ")
    }

    private func formattedTimestamp() -> String {
        if let songTimestamp = song.listened_at {
            let timeSeconds = TimeInterval(songTimestamp) / 1000.0
            let date = Date(timeIntervalSince1970: TimeInterval(timeSeconds))
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return formatter.localizedString(for: date, relativeTo: Date())
        }
        return ""
    }
}
