import SwiftUI

struct CreatePostModal: View {
    let onClosePressed: () -> Void
    let onCreatePost: (String) -> Void

    @State private var isCreating = false
    @State private var caption: String = ""

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.themeElement.opacity(0.5))
                .frame(width: 40, height: 5)
                .padding(.top, 12)

            HStack {
                Spacer()
                Button(action: {
                    caption = ""
                    onClosePressed()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color.themePrimary.opacity(0.5))
                }
                .padding(.trailing, 16)
                .padding(.top, 8)
            }

            VStack(alignment: .leading, spacing: 20) {
                Text("Add a caption (optional)")
                    .font(.headline)
                    .foregroundColor(Color.themePrimary)
                    .padding(.top, 8)

                TextEditor(text: $caption)
                    .font(.subheadline)
                    .scrollContentBackground(.hidden)
                    .foregroundColor(Color.themePrimary)
                    .frame(minHeight: 100, maxHeight: 150)
                    .padding(12)
                    .background(Color.themeElement.opacity(0.3))
                    .cornerRadius(10)
                    .tint(Color.themeAccent)
                    .overlay(
                        Group {
                            if caption.isEmpty {
                                Text("What's on your mind?")
                                    .font(.subheadline)
                                    .foregroundColor(Color.themePrimary.opacity(0.4))
                                    .padding(.leading, 16)
                                    .padding(.top, 20)
                                    .allowsHitTesting(false)
                            }
                        },
                        alignment: .topLeading
                    )

                Button(action: {
                    guard !isCreating else { return }
                    isCreating = true
                    onCreatePost(caption)
                    caption = ""
                }) {
                    HStack {
                        if isCreating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isCreating ? "Posting..." : "Post")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(isCreating ? Color.themeAccent.opacity(0.6) : Color.themeAccent)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isCreating)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(Color.themeElement)
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(color: Color.themeShadow, radius: 20, x: 0, y: -5)
    }
}
