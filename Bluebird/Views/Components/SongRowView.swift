import SwiftUI

struct SongRowView: View {
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
                Text(song.artistName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isPlaying {
                Text("playing")
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
