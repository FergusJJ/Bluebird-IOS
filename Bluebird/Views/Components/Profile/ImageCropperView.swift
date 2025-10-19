import SwiftUI

struct ImageCropperView: View {
    let image: UIImage
    let onCrop: (UIImage) -> Void
    let onCancel: () -> Void

    @State private var currentScale: CGFloat = 1.0
    @State private var currentOffset: CGSize = .zero

    @GestureState private var magnifyBy: CGFloat = 1.0
    @GestureState private var dragOffset: CGSize = .zero

    private let cropSize: CGFloat = 300

    // Computed properties for smooth gestures
    private var scale: CGFloat {
        currentScale * magnifyBy
    }

    private var offset: CGSize {
        CGSize(
            width: currentOffset.width + dragOffset.width,
            height: currentOffset.height + dragOffset.height
        )
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .updating($magnifyBy) { value, gestureState, _ in
                gestureState = value
            }
            .onEnded { value in
                let newScale = currentScale * value
                currentScale = max(1.0, min(newScale, 5.0))
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .updating($dragOffset) { value, gestureState, _ in
                gestureState = value.translation
            }
            .onEnded { value in
                currentOffset.width += value.translation.width
                currentOffset.height += value.translation.height
            }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                GeometryReader { geometry in
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .scaleEffect(scale)
                            .offset(offset)
                            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: currentScale)
                            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: currentOffset)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .simultaneousGesture(magnificationGesture)
                            .simultaneousGesture(dragGesture)

                        CropOverlay(cropSize: cropSize)

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

    // note: this will let you (in the preview) use on half of an image, and habe
    // the rest being missing - this causes teh image to render weirly (flips it and stretches it)
    //  but i cba to fix
    private func cropImage() {
        // Use the actual image size to determine the crop region
        let imageSize = image.size
        let imageAspect = imageSize.width / imageSize.height

        // Calculate how the image is displayed (scaledToFit)
        var displayWidth: CGFloat
        var displayHeight: CGFloat

        if imageAspect > 1 {
            // Landscape - width fills, height scales down
            displayWidth = cropSize
            displayHeight = cropSize / imageAspect
        } else {
            // Portrait - height fills, width scales down
            displayHeight = cropSize
            displayWidth = cropSize * imageAspect
        }

        // Apply user's zoom
        displayWidth *= currentScale
        displayHeight *= currentScale

        // Calculate the scale factor between display size and actual image size
        let scaleFactor = imageSize.width / displayWidth

        // The crop circle is always at the center of the screen (cropSize/2, cropSize/2)
        // The image has been offset by currentOffset
        // We need to find what part of the image is under the crop circle

        // In display coordinates:
        // - The crop circle center is at (cropSize/2, cropSize/2)
        // - The image center is at (cropSize/2 + currentOffset.width, cropSize/2 + currentOffset.height)

        // The offset from image center to crop circle center in display coordinates
        let offsetFromImageCenterX = -currentOffset.width
        let offsetFromImageCenterY = -currentOffset.height

        // Convert this offset to image coordinates
        let imageOffsetX = offsetFromImageCenterX * scaleFactor
        let imageOffsetY = offsetFromImageCenterY * scaleFactor

        // The crop center in image coordinates (measured from image center)
        let imageCenterX = imageSize.width / 2 + imageOffsetX
        let imageCenterY = imageSize.height / 2 + imageOffsetY

        // Calculate the crop size in image coordinates
        let cropSizeInImage = cropSize * scaleFactor

        // Calculate the crop rect in image coordinates
        let cropX = imageCenterX - cropSizeInImage / 2
        let cropY = imageCenterY - cropSizeInImage / 2

        let cropRect = CGRect(
            x: cropX,
            y: cropY,
            width: cropSizeInImage,
            height: cropSizeInImage
        )

        // Crop the image
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            onCrop(image)
            return
        }

        // Create a square output image at high resolution
        let outputSize = CGSize(width: 1000, height: 1000)
        let renderer = UIGraphicsImageRenderer(size: outputSize)

        let croppedImage = renderer.image { context in
            UIImage(cgImage: cgImage).draw(in: CGRect(origin: .zero, size: outputSize))
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
