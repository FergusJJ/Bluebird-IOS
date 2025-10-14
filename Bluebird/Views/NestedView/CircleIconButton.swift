import SwiftUI

struct CircleIconButton: View {
    let systemName: String
    var iconColor: Color = .themePrimary
    var backgroundColor: Color = Color.themeElement.opacity(0.9)
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 44, height: 44)
                .background(
                    ZStack {
                        backgroundColor
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.themeHighlight.opacity(0.1),
                                        Color.clear,
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                )
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.themeHighlight, lineWidth: 1)
                )
                .shadow(color: Color.themeShadow, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
