import SwiftUI

struct HourlyPlaysClockView: View {
    let hourlyPlays: [Int]
    @State private var selectedHour: Int? = nil

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.themeElement.opacity(0.4))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                content(in: geo.size)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private func content(in size: CGSize) -> some View {
        let padding: CGFloat = 12
        let availableSize = min(
            size.width - padding * 2,
            size.height - padding * 2
        )
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let innerRadius = availableSize * 0.18
        let outerRadius = availableSize * 0.375
        let maxBarLen = outerRadius - innerRadius
        let maxPlays = max(CGFloat(hourlyPlays.max() ?? 0), 1)
        let outerCircleWH = max(availableSize * 0.75, 0)
        let innerCirlceWH = max(availableSize * 0.04, 0)
        ZStack {
            Circle()
                .fill(Color.themeElement.opacity(0.3))
                .frame(width: outerCircleWH, height: outerCircleWH)
            Circle()
                .fill(Color.themeAccent.opacity(0.4))
                .frame(width: innerCirlceWH, height: innerCirlceWH)

            ForEach(0 ..< 24, id: \.self) { hour in
                bar(
                    for: hour,
                    center: center,
                    innerRadius: innerRadius,
                    maxBarLen: maxBarLen,
                    maxPlays: maxPlays,
                    minSide: availableSize
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedHour = selectedHour == hour ? nil : hour
                    }
                }
            }

            Text("12am")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.themePrimary)
                .position(
                    x: center.x - availableSize * 0.03,
                    y: center.y - availableSize * 0.42
                )

            Text("6am")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.themePrimary)
                .position(x: center.x + availableSize * 0.42, y: center.y)

            Text("12pm")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.themePrimary)
                .position(
                    x: center.x + availableSize * 0.03,
                    y: center.y + availableSize * 0.42
                )

            Text("6pm")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.themePrimary)
                .position(x: center.x - availableSize * 0.42, y: center.y)

            if let selectedHour = selectedHour {
                selectionPopup(
                    for: selectedHour,
                    center: center,
                    radius: availableSize * 0.36
                )
            }
        }
    }

    @ViewBuilder
    private func bar(
        for hour: Int,
        center: CGPoint,
        innerRadius: CGFloat,
        maxBarLen: CGFloat,
        maxPlays: CGFloat,
        minSide: CGFloat
    ) -> some View {
        let angle = Angle.degrees(Double(hour) / 24.0 * 360.0 - 90)
        let plays = CGFloat(hourlyPlays[hour])
        let normalizedLength = plays / maxPlays
        let barLength = max(
            normalizedLength * maxBarLen,
            plays > 0 ? minSide * 0.015 : 0
        )
        let isSelected = selectedHour == hour

        let cosAngle = CGFloat(cos(angle.radians))
        let sinAngle = CGFloat(sin(angle.radians))

        let startPoint = CGPoint(
            x: center.x + cosAngle * innerRadius,
            y: center.y + sinAngle * innerRadius
        )
        let endPoint = CGPoint(
            x: center.x + cosAngle * (innerRadius + barLength),
            y: center.y + sinAngle * (innerRadius + barLength)
        )

        let arcLength = 2 * .pi * innerRadius / 24
        let baseWidth = arcLength * 0.75
        let lineWidth = isSelected ? baseWidth * 1.15 : baseWidth

        Path { path in
            path.move(to: startPoint)
            path.addLine(to: endPoint)
        }
        .stroke(
            barGradient(
                plays: plays,
                isSelected: isSelected,
                normalizedLength: normalizedLength
            ),
            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
        )
        .opacity(isSelected ? 1.0 : plays == 0 ? 0.3 : 0.95)
    }

    private func barGradient(
        plays: CGFloat,
        isSelected: Bool,
        normalizedLength: CGFloat
    ) -> LinearGradient {
        if plays == 0 {
            return LinearGradient(
                colors: [
                    Color.themeAccent.opacity(0.1), Color.themeAccent.opacity(0.05),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        let intensity = 0.6 + (normalizedLength * 0.4)
        let baseColor = Color.themeAccent

        return LinearGradient(
            colors: isSelected
                ? [baseColor.opacity(0.9), baseColor]
                : [
                    baseColor.opacity(intensity * 0.6),
                    baseColor.opacity(intensity),
                ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    @ViewBuilder
    private func selectionPopup(for hour: Int, center: CGPoint, radius: CGFloat)
        -> some View
    {
        let position = calculatePopupPosition(
            for: hour,
            center: center,
            radius: radius
        )

        VStack(spacing: 2) {
            Text("\(hourlyPlays[hour])")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(Color.themePrimary)
            Text("plays at \(formatHour(hour))")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.themePrimary.opacity(0.6))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.themeElement.opacity(0.95))
                .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 4)
        )
        .position(position)
        .transition(.scale.combined(with: .opacity))
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedHour = nil
            }
        }
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"

        var components = DateComponents()
        components.hour = hour

        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date).lowercased()
        }

        return "\(hour):00"
    }

    private func calculatePopupPosition(
        for hour: Int,
        center: CGPoint,
        radius: CGFloat
    ) -> CGPoint {
        let angle = Angle.degrees(Double(hour) / 24.0 * 360.0 - 90)
        let popupDistance = radius + 55

        return CGPoint(
            x: center.x + CGFloat(cos(angle.radians)) * popupDistance,
            y: center.y + CGFloat(sin(angle.radians)) * popupDistance
        )
    }
}
