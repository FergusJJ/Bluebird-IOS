import SwiftUI

struct SongSlot: View {
    let currentlyPlaying: Bool
    let song: String
    let artists: String
    let imageURL: URL?

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 60, height: 60)
                        .background(Color(.systemGray))

                case let .success(image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)

                case .failure:
                    Image(systemName: "photo.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(10)
                        .foregroundColor(.secondary)
                        .background(Color(.systemGray))

                @unknown default:
                    EmptyView()
                        .frame(width: 60, height: 60)
                        .background(Color(.systemGray))
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(radius: 3)

            VStack(alignment: .leading) {
                Text(song)
                    .font(.headline)
                    .lineLimit(1)

                Text(artists)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(10)
        .background(Color(.systemGray))
        .cornerRadius(10)
    }
}
