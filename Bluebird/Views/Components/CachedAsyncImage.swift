import SwiftUI

struct CachedAsyncImage: View {
    let url: URL

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
            } else {
                Color.gray.opacity(0.3)
            }
        }
        .onAppear(perform: loadImage)
    }

    private func loadImage() {
        if let cachedImage = ImageCache.shared.image(for: url) {
            image = cachedImage
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil,
                  let downloadedImage = UIImage(data: data)
            else {
                return
            }
            ImageCache.shared.setImage(downloadedImage, for: url)
            DispatchQueue.main.async {
                self.image = downloadedImage
            }
        }.resume()
    }
}
