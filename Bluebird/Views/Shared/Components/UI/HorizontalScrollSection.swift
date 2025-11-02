import SwiftUI

enum ClipShape {
    case rounded
    case circle
    case square
}

struct HorizontalScrollSection<T: Identifiable>: View {
    let title: String
    let items: [T]
    let clipShape: ClipShape
    let onTap: ((T) -> Void)?

    let getName: (T) -> String
    let getImageURL: (T) -> String

    init(
        title: String,
        items: [T],
        clipShape: ClipShape = .rounded,
        getName: @escaping (T) -> String,
        getImageURL: @escaping (T) -> String,
        onTap: ((T) -> Void)? = nil
    ) {
        self.title = title
        self.items = items
        self.clipShape = clipShape
        self.getName = getName
        self.getImageURL = getImageURL
        self.onTap = onTap
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .foregroundStyle(Color.themePrimary)
                .font(.subheadline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(items) { item in
                        ItemView(
                            name: getName(item),
                            imageURL: getImageURL(item),
                            clipShape: clipShape
                        ) {
                            onTap?(item)
                        }
                    }
                }
            }
            .padding(.vertical, 10)
        }
    }
}

// MARK: - Item View

struct ItemView: View {
    let name: String
    let imageURL: String
    let clipShape: ClipShape
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            CachedAsyncImage(url: URL(string: imageURL)!)
                .aspectRatio(contentMode: .fill)
                // .frame(width: 80, height: 80)
                .frame(width: 100, height: 100)
                .clipShape(clipShapeView)

            Text(name)
                .font(.caption)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 100)
                .foregroundStyle(Color.themePrimary)
                .lineLimit(2)
                .truncationMode(.tail)
        }
        .onTapGesture {
            onTap()
        }
    }

    private var clipShapeView: AnyShape {
        switch clipShape {
        case .rounded:
            AnyShape(RoundedRectangle(cornerRadius: 2))
        case .circle:
            AnyShape(Circle())
        case .square:
            AnyShape(Rectangle())
        }
    }
}

// for convenience
extension HorizontalScrollSection where T == AlbumSummary {
    static func albums(
        title: String,
        items: [AlbumSummary],
        onTap: ((AlbumSummary) -> Void)? = nil
    ) -> HorizontalScrollSection<AlbumSummary> {
        HorizontalScrollSection(
            title: title,
            items: items,
            clipShape: .rounded,
            getName: { $0.name },
            getImageURL: { $0.image_url },
            onTap: onTap
        )
    }
}

extension HorizontalScrollSection where T == TopTrack {
    static func tracks(
        title: String,
        items: [TopTrack],
        onTap: ((TopTrack) -> Void)? = nil
    ) -> HorizontalScrollSection<TopTrack> {
        HorizontalScrollSection(
            title: title,
            items: items,
            clipShape: .rounded,
            getName: { $0.name },
            getImageURL: { $0.image_url },
            onTap: onTap
        )
    }
}

// Note: do not use if expecting spotify_uri to be the actual spotify URI
// if called with ArtistDetail as T (i.e. after fetchign pins) then spotify_uri is most likely
// an image
extension HorizontalScrollSection where T == ArtistDetail {
    static func artists(
        title: String,
        items: [ArtistDetail],
        onTap: ((ArtistDetail) -> Void)? = nil
    ) -> HorizontalScrollSection<ArtistDetail> {
        HorizontalScrollSection(
            title: title,
            items: items,
            clipShape: .circle,
            getName: { $0.name },
            getImageURL: { $0.spotify_uri }, // This is a mistake on my part, should be renamed.
            onTap: onTap
        )
    }
}

extension HorizontalScrollSection where T == SongDetail {
    static func tracks(
        title: String,
        items: [SongDetail],
        onTap: ((SongDetail) -> Void)? = nil
    ) -> HorizontalScrollSection<SongDetail> {
        HorizontalScrollSection(
            title: title,
            items: items,
            clipShape: .square,
            getName: { $0.name },
            getImageURL: { $0.album_image_url },
            onTap: onTap
        )
    }
}

extension HorizontalScrollSection where T == AlbumDetail {
    static func albums(
        title: String,
        items: [AlbumDetail],
        onTap: ((AlbumDetail) -> Void)? = nil
    ) -> HorizontalScrollSection<AlbumDetail> {
        HorizontalScrollSection(
            title: title,
            items: items,
            clipShape: .square,
            getName: { $0.name },
            getImageURL: { $0.image_url },
            onTap: onTap
        )
    }
}
