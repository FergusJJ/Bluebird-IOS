import SwiftUI

struct RowItem<Destination: View>: View {
    let title: String
    let imageURL: String
    let clipShape: AnyShape
    let systemImage: String
    let destination: (() -> Destination)?

    init(
        title: String,
        imageURL: String,
        clipShape: AnyShape,
        systemImage: String,
        destination: (() -> Destination)? = nil
    ) {
        self.title = title
        self.imageURL = imageURL
        self.clipShape = clipShape
        self.systemImage = systemImage
        self.destination = destination
    }

    var body: some View {
        Group {
            if let destination = destination {
                NavigationLink(destination: destination()) {
                    rowContent
                }
            } else {
                rowContent
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            if let url = URL(string: imageURL) {
                CachedAsyncImage(url: url)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(clipShape)
            }

            Text(title)
                .font(.headline)
                .foregroundStyle(Color.themePrimary)
                .lineLimit(1)

            Spacer()

            Image(systemName: systemImage)
                .foregroundStyle(Color.themePrimary)
        }
    }
}
