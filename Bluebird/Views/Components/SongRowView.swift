import SwiftUI

struct SongRowView: View {
    @State private var animationTrigger = 0

    let song: DisplayableSong
    let isPlaying: Bool

    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: song.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "photo.fill")
            }
            .frame(width: 50, height: 50)
            .cornerRadius(4)

            VStack(alignment: .leading, spacing: 4) {
                Text(song.trackName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Text(song.artistName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .allowsTightening(true)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }

            Spacer()

            if isPlaying {
                Image(systemName: "waveform")
                    .symbolEffect(.bounce, options: .speed(0.5), value: animationTrigger)
                    .frame(width: 45, alignment: .trailing)
                    .font(.subheadline)
                    .onAppear {
                        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                            animationTrigger += 1
                        }
                    }
            } else {
                Text(formattedTimestamp())
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 45, alignment: .trailing)
            }
        }
    }

    private func formattedTimestamp() -> String {
        if let historySong = song as? ViewSongExt {
            let timeSeconds = TimeInterval(historySong.listenedAt) / 1000.0
            let date = Date(timeIntervalSince1970: TimeInterval(timeSeconds))
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return formatter.localizedString(for: date, relativeTo: Date())
        }
        return ""
    }
}
