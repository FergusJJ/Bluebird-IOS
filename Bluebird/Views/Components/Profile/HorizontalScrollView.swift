import SwiftUI

struct HorizontalScrollView: View {
    let horizontalScrollViewTitle: String
    let scrollViewObjects: [ScrollViewObject]

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(horizontalScrollViewTitle)
                .foregroundStyle(Color.nearWhite)
                .font(.subheadline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(scrollViewObjects) { object in
                        ScrollViewItemView(
                            object: object,
                            isCircle: horizontalScrollViewTitle
                                == "Pinned Artists"
                        )
                    }
                }
            }
            .padding(.vertical, 10)
        }
    }
}

struct ScrollViewItemView: View {
    let object: ScrollViewObject
    let isCircle: Bool
    var body: some View {
        VStack(spacing: 4) {
            CachedAsyncImage(url: object.imageURL)
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipShape(
                    isCircle
                        ? AnyShape(Circle())
                        : AnyShape(RoundedRectangle(cornerRadius: 2))
                )
            Text(object.name)
                .font(.caption)
                .foregroundStyle(Color.nearWhite)
                .lineLimit(1)
        }
    }
}
