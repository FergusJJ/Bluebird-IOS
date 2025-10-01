import SwiftUI

enum CustomFontSize {
    case semantic(Font)
    case point(Int)
}

struct TwoStatsView: View {
    let leftLabel: String
    let leftValue: String?
    let rightLabel: String
    let rightValue: String?

    let valueFontSize: CustomFontSize

    @State private var leftOpacity: Double = 0.3
    @State private var rightOpacity: Double = 0.3

    var body: some View {
        HStack(spacing: 0) {
            statColumn(
                label: leftLabel,
                value: leftValue,
                opacity: $leftOpacity
            )
            Divider()
                .frame(height: 40)
                .background(Color.lightGray.opacity(0.3))
            statColumn(
                label: rightLabel,
                value: rightValue,
                opacity: $rightOpacity
            )
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.darkElement)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.lightGray.opacity(0.1), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func statColumn(
        label: String,
        value: String?,
        opacity: Binding<Double>
    ) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.lightGray)
                .textCase(.uppercase)

            if let value = value {
                Text(value)
                    .font(resolveFont())
                    .fontWeight(.semibold)
                    .foregroundColor(.nearWhite)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.lightGray.opacity(0.3))
                    .frame(width: 50, height: 16)
                    .opacity(opacity.wrappedValue)
                    .onAppear {
                        animateOpacity(opacity)
                    }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func animateOpacity(_ opacity: Binding<Double>) {
        withAnimation(
            Animation.easeInOut(duration: 1.2)
                .repeatForever(autoreverses: true)
        ) {
            opacity.wrappedValue = 1.0
        }
    }

    private func resolveFont() -> Font {
        switch valueFontSize {
        case let .semantic(font):
            return font
        case let .point(size):
            return .system(size: CGFloat(size))
        }
    }
}
