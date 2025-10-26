import SwiftUI

struct ImageCropperView: View {
    let image: UIImage
    let onCancel: () -> Void
    let onCrop: (UIImage) -> Void

    private let targetCropSize: CGFloat = 100.0
    private let displayCropSize: CGFloat = 250.0

    @State private var debugBLImage: CGPoint = .zero
    @State private var debugBRImage: CGPoint = .zero
    @State private var debugTLImage: CGPoint = .zero
    @State private var debugTRImage: CGPoint = .zero

    @State private var debugTLCropPoint: CGPoint = .zero

    @State private var prevOffset: CGSize = .zero
    @State private var offset: CGSize = .zero
    @State private var containerSize: CGSize = .zero

    init(
        image: UIImage,
        onCancel: @escaping () -> Void,
        onCrop: @escaping (UIImage) -> Void
    ) {
        self.image = Self.normailzeOrientation(image)
        self.onCancel = onCancel
        self.onCrop = onCrop

    }

    var body: some View {
        NavigationView {
            GeometryReader { geometryProxy in
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .offset(offset)
                        .simultaneousGesture(dragGesture)
                   /*
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                        .offset(
                            x: debugTLImage.x,
                            y: debugTLImage.y
                        )

                    Circle()
                        .fill(Color.blue)
                        .frame(width: 10, height: 10)
                        .offset(
                            x: debugTRImage.x,
                            y: debugTRImage.y
                        )

                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 10, height: 10)
                        .offset(x: debugBLImage.x, y: debugBLImage.y)

                    Circle()
                        .fill(Color.purple)
                        .frame(width: 10, height: 10)
                        .offset(x: debugBRImage.x, y: debugBRImage.y)

                    Circle()
                        .fill(Color.orange)
                        .frame(width: 10, height: 10)
                        .offset(x: debugTLCropPoint.x, y: debugTLCropPoint.y)

                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
*/
                    CropOverlay(cropSize: displayCropSize, cx: -1, cy: -1)

                    VStack {
                        Spacer()
                        Text("Drag to reposition")
                            .font(.subheadline)
                            .padding(.bottom, 40)
                    }
                }
                .onAppear {
                    containerSize = geometryProxy.size
                    updateDebugPoints()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        /**

                        need to figure out the bounds of the corners of the square which
                            captures the circle.
                         not sure how the zoon/will effect the translatioon vice versa

                         */
                        onCancel()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        print("Done clicked")
                        let maybeCroppedImage = cropImage()
                        if let croppedImage = maybeCroppedImage {
                            onCrop(croppedImage)
                            return
                        }
                        print("error cropping image")
                        // apply transformation to image
                        //onCrop()
                    }
                    .foregroundColor(Color.themeAccent)
                    .fontWeight(.semibold)
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.9), for: .navigationBar)

        }
    }

    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { offsetDelta in

                withAnimation(.easeOut) {
                    offset = CGSize(
                        width: prevOffset.width + offsetDelta.translation.width,
                        height: prevOffset.height
                            + offsetDelta.translation.height
                    )
                    updateDebugPoints()
                }

            }.onEnded { _ in
                pinImageToContainer()
                updateDebugPoints()
                prevOffset = offset
            }
    }

    private func calcMetrics(containerSize: CGSize, debug: Bool = false) -> (
        scaleRatio: CGFloat, imageOffset: CGSize, drawnImageSize: CGSize
    ) {
        let imageRatio = image.size.width / image.size.height
        let containerRatio = containerSize.width / containerSize.height
        if debug {
            print(
                "[DEBUG]\nimage image_width: \(image.size.width) | container_width: \(containerSize.width)\nimage_height: \(image.size.height) | container_height: \(containerSize.height)\nimage_ratio:\(imageRatio) | container_ratio: \(containerRatio)"
            )
            print("[DEBUG] orientation: \(image.imageOrientation)")

        }
        var drawnImageSize: CGSize

        var scaleRatio: CGFloat  // transformatrion from 'image space' to 'screen space'
        if imageRatio > containerRatio {
            //height shrunk to fit full image in screen
            scaleRatio = (image.size.width * image.scale) / containerSize.width
            drawnImageSize = CGSize(
                width: containerSize.width,
                height: containerSize.width / imageRatio
            )
        } else {
            //image is more portrait than container is
            // so width has been shrunk
            scaleRatio =
                (image.size.height * image.scale) / containerSize.height
            drawnImageSize = CGSize(
                width: containerSize.height * imageRatio,  // maintain aspect ratio using new height
                height: containerSize.height
            )
        }
        let imageOffset = CGSize(
            width: (containerSize.width - drawnImageSize.width) / 2,
            height: (containerSize.height - drawnImageSize.height) / 2
        )

        return (scaleRatio, imageOffset, drawnImageSize)
    }

    private func cropImage() -> UIImage? {
        guard containerSize != .zero else {
            print("Erro: container size not captured")
            return nil
        }
        let (scaleRatio, imageOffset, _) = calcMetrics(
            containerSize: containerSize,
            debug: true
        )
        let centerScreen = CGPoint(
            x: containerSize.width / 2,
            y: containerSize.height / 2
        )
        let centerImageCropPoint = CGPoint(
            x: centerScreen.x - offset.width - imageOffset.width,
            y: centerScreen.y - offset.height - imageOffset.height
        )
        let cropCx = centerImageCropPoint.x * scaleRatio
        let cropCy = centerImageCropPoint.y * scaleRatio

        // size of the crop rectangle in 'image space'
        let cropSizeOnImage = displayCropSize * scaleRatio

        let cropRect = CGRect(
            x: cropCx - (cropSizeOnImage / 2.0),
            y: cropCy - (cropSizeOnImage / 2.0),
            width: cropSizeOnImage,
            height: cropSizeOnImage
        )

        guard let cropImageRef: CGImage = image.cgImage?.cropping(to: cropRect)
        else {
            print("Failed to crop image using: \(cropRect)")
            return nil
        }
        let croppedImage: UIImage = UIImage(
            cgImage: cropImageRef,
            scale: image.scale,
            orientation: image.imageOrientation
        )
        let finalImage = resizeImage(
            image: croppedImage,
            to: CGSize(width: targetCropSize, height: targetCropSize)
        )
        return finalImage
    }

    private func updateDebugPoints() {
        guard containerSize != .zero else { return }
        let (_, imageOffset, drawnImageSize) = calcMetrics(
            containerSize: containerSize
        )  // Capture drawnImageSize

        // 1. Calculate the Top-Left corner position (relative to screen center)
        let imageTopLeftFromContainerOrigin = CGPoint(
            x: imageOffset.width + offset.width,
            y: imageOffset.height + offset.height
        )

        self.debugTLImage = CGPoint(
            x: imageTopLeftFromContainerOrigin.x - containerSize.width / 2,
            y: imageTopLeftFromContainerOrigin.y - containerSize.height / 2
        )

        // Use the TL point and drawnImageSize to find the other corners:
        let drawnWidth = drawnImageSize.width
        let drawnHeight = drawnImageSize.height

        // 2. Top-Right (TR)
        self.debugTRImage = CGPoint(
            x: debugTLImage.x + drawnWidth,
            y: debugTLImage.y
        )

        // 3. Bottom-Left (BL)
        self.debugBLImage = CGPoint(
            x: debugTLImage.x,
            y: debugTLImage.y + drawnHeight
        )

        // 4. Bottom-Right (BR)
        self.debugBRImage = CGPoint(
            x: debugTLImage.x + drawnWidth,
            y: debugTLImage.y + drawnHeight
        )

        // 5. Top-Left Crop Point (Fixed orange dot)
        self.debugTLCropPoint = CGPoint(
            x: -displayCropSize / 2.0,
            y: -displayCropSize / 2.0
        )
    }

    private func pinImageToContainer() {
        guard containerSize != .zero else { return }

        let (_, imageOffset, drawnImageSize) = calcMetrics(
            containerSize: containerSize
        )
        let halfCropSize = displayCropSize / 2.0

        let cropTL_x = -halfCropSize
        let cropTL_y = -halfCropSize
        let cropBR_x = halfCropSize
        let cropBR_y = halfCropSize
        var newOffset = offset

        // Calculate the drawn image's Top-Left (x, y) relative to screen center (0,0) based on the *current* offset
        let currentTL_x =
            imageOffset.width + offset.width - containerSize.width / 2
        let currentTL_y =
            imageOffset.height + offset.height - containerSize.height / 2
        let currentBR_x = currentTL_x + drawnImageSize.width
        let currentBR_y = currentTL_y + drawnImageSize.height

        if currentTL_x > cropTL_x {
            // shoft left
            let dx = cropTL_x - currentTL_x
            newOffset.width += dx
        } else if currentBR_x < cropBR_x {
            // SHift image right
            let dx = cropBR_x - currentBR_x
            newOffset.width += dx
        }

        if currentTL_y > cropTL_y {
            // Shift image up
            let dy = cropTL_y - currentTL_y
            newOffset.height += dy
        } else if currentBR_y < cropBR_y {
            // shif image down
            let dy = cropBR_y - currentBR_y
            newOffset.height += dy
        }

        withAnimation(.easeOut(duration: 0.2)) {
            self.offset = newOffset
        }
    }

    private func resizeImage(image: UIImage, to target: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: target)
        let newImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return newImage

    }

    private static func normailzeOrientation(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up {
            return image
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        let normalized = renderer.image { ctx in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        return normalized
    }
}

struct CropOverlay: View {
    let cropSize: CGFloat
    let cx: CGFloat
    let cy: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack {

                // Top dimmed area
                Rectangle()
                    .fill(Color.black.opacity(0.6))
                    .frame(height: (geometry.size.height - cropSize) / 2)
                    .frame(maxWidth: .infinity)
                    // places center of rectagle in middle of geoetry and then in top quater
                    .position(
                        x: geometry.size.width / 2,
                        y: (geometry.size.height - cropSize) / 4
                    )

                // Bottom dimmed area
                Rectangle()
                    .fill(Color.black.opacity(0.6))
                    .frame(height: (geometry.size.height - cropSize) / 2)
                    .frame(maxWidth: .infinity)
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height
                            - (geometry.size.height - cropSize) / 4
                    )

                // Left dimmed area
                Rectangle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: (geometry.size.width - cropSize) / 2)
                    .frame(maxHeight: .infinity)
                    .position(
                        x: (geometry.size.width - cropSize) / 4,
                        y: geometry.size.height / 2
                    )

                // Right dimmed area
                Rectangle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: (geometry.size.width - cropSize) / 2)
                    .frame(maxHeight: .infinity)
                    .position(
                        x: geometry.size.width
                            - (geometry.size.width - cropSize) / 4,
                        y: geometry.size.height / 2
                    )
                /*
                                Circle()
                                    .stroke(Color.red, lineWidth: 3)
                                    .frame(width: cropSize, height: cropSize)
                                    .position(
                                        x: cx,
                                        y: cy
                                    )
                                    .allowsHitTesting(false)
                */
                // Crop frame border (circular)
                Circle()
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: cropSize, height: cropSize)
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 2
                    )
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
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height / 2
                )
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
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height / 2
                )
                .allowsHitTesting(false)
            }
            .allowsHitTesting(false)
        }
    }
}
