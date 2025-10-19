import SwiftUI

struct ImageCropperView: View {
    let image: UIImage
    let onCrop: (UIImage) -> Void
    let onCancel: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let cropSize: CGFloat = 300

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                GeometryReader { geometry in
                    ZStack {
                        // The image
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(scale)
                            .offset(offset)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let newScale = lastScale * value
                                        scale = max(1.0, min(newScale, 5.0)) // Limit zoom between 1x and 5x
                                    }
                                    .onEnded { _ in
                                        lastScale = scale
                                    }
                            )
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    }
                            )

                        // Crop overlay
                        CropOverlay(cropSize: cropSize)

                        // Instructions at bottom
                        VStack {
                            Spacer()
                            Text("Pinch to zoom, drag to reposition")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(20)
                                .padding(.bottom, 40)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        cropImage()
                    }
                    .foregroundColor(Color.themeAccent)
                    .fontWeight(.semibold)
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.9), for: .navigationBar)
        }
    }

    private func cropImage() {
        // High resolution for better quality
        let outputSize = CGSize(width: 1000, height: 1000)
        let scaleFactor = outputSize.width / cropSize

        let renderer = UIGraphicsImageRenderer(size: outputSize)

        let croppedImage = renderer.image { context in
            // Calculate the base size of the image in the view
            let imageSize = image.size
            let imageAspect = imageSize.width / imageSize.height

            var baseWidth: CGFloat
            var baseHeight: CGFloat

            // Fit the image in the view (before any user scaling)
            if imageAspect > 1 {
                // Landscape - fit to width
                baseWidth = cropSize
                baseHeight = cropSize / imageAspect
            } else {
                // Portrait - fit to height
                baseHeight = cropSize
                baseWidth = cropSize * imageAspect
            }

            // Apply user's scale
            let finalWidth = baseWidth * scale * scaleFactor
            let finalHeight = baseHeight * scale * scaleFactor

            // Apply user's offset (scaled to output size)
            let finalX = (outputSize.width - finalWidth) / 2 + (offset.width * scaleFactor)
            let finalY = (outputSize.height - finalHeight) / 2 + (offset.height * scaleFactor)

            let drawRect = CGRect(x: finalX, y: finalY, width: finalWidth, height: finalHeight)

            // Draw the image
            image.draw(in: drawRect)
        }

        onCrop(croppedImage)
    }
}

struct CropOverlay: View {
    let cropSize: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Top dimmed area
                Rectangle()
                    .fill(Color.black.opacity(0.6))
                    .frame(height: (geometry.size.height - cropSize) / 2)
                    .frame(maxWidth: .infinity)
                    .position(x: geometry.size.width / 2, y: (geometry.size.height - cropSize) / 4)

                // Bottom dimmed area
                Rectangle()
                    .fill(Color.black.opacity(0.6))
                    .frame(height: (geometry.size.height - cropSize) / 2)
                    .frame(maxWidth: .infinity)
                    .position(x: geometry.size.width / 2, y: geometry.size.height - (geometry.size.height - cropSize) / 4)

                // Left dimmed area
                Rectangle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: (geometry.size.width - cropSize) / 2, height: cropSize)
                    .position(x: (geometry.size.width - cropSize) / 4, y: geometry.size.height / 2)

                // Right dimmed area
                Rectangle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: (geometry.size.width - cropSize) / 2, height: cropSize)
                    .position(x: geometry.size.width - (geometry.size.width - cropSize) / 4, y: geometry.size.height / 2)

                // Crop frame border (circular)
                Circle()
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: cropSize, height: cropSize)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    .allowsHitTesting(false)

                // Grid lines - horizontal
                VStack(spacing: 0) {
                    Spacer()
                    Rectangle()
                        .fill(Color.white.opacity(0.5))
                        .frame(height: 1)
                    Spacer()
                    Rectangle()
                        .fill(Color.white.opacity(0.5))
                        .frame(height: 1)
                    Spacer()
                }
                .frame(width: cropSize, height: cropSize)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                .allowsHitTesting(false)

                // Grid lines - vertical
                HStack(spacing: 0) {
                    Spacer()
                    Rectangle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 1)
                    Spacer()
                    Rectangle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 1)
                    Spacer()
                }
                .frame(width: cropSize, height: cropSize)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                .allowsHitTesting(false)
            }
            .allowsHitTesting(false)
        }
    }
}
