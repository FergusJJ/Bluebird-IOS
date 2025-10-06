import SwiftUI

struct TrackTrendBarGraph: View {
    let trackTrend: [DailyPlayCount]
    @State private var selectedDay: Date? = nil
    @State private var animateIn = false
    @State private var showLast7Days = false

    private let calendar = Calendar.current

    // fill gaps with zero counts, not populated in response
    private var displayData: [DailyPlayCount] {
        let endDate = calendar.startOfDay(for: Date())
        let daysToShow = showLast7Days ? 7 : 30
        guard
            let startDate = calendar.date(
                byAdding: .day,
                value: -(daysToShow - 1),
                to: endDate
            )
        else {
            return []
        }

        var result: [DailyPlayCount] = []
        var currentDate = startDate

        while currentDate <= endDate {
            if let existing = trackTrend.first(where: {
                calendar.isDate($0.day, inSameDayAs: currentDate)
            }) {
                result.append(existing)
            } else {
                result.append(DailyPlayCount(day: currentDate, count: 0))
            }
            currentDate = calendar.date(
                byAdding: .day,
                value: 1,
                to: currentDate
            )!
        }

        return result
    }

    var body: some View {
        GeometryReader { geo in
            content(in: geo.size)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animateIn = true
            }
        }
    }

    @ViewBuilder
    private func content(in size: CGSize) -> some View {
        let data = displayData
        let maxPlays = max(
            CGFloat(data.map { $0.count }.max() ?? 0),
            1
        )
        let horizontalPadding: CGFloat = 32
        let availableWidth = size.width - (horizontalPadding * 2)
        let barWidth = availableWidth / CGFloat(data.count)
        let spacing = barWidth * 0.15
        let actualBarWidth = barWidth - spacing

        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.themeElement.opacity(0.4))
                    .shadow(color: .themeShadow, radius: 4, x: 0, y: 2)
                HStack {
                    Text(showLast7Days ? "Last 7 Days" : "Last 30 Days")
                        .font(.system(size: 14, weight: .semibold))
                    Image(systemName: "arrow.left.arrow.right.circle")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.themePrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.themeBackground.opacity(0.8))
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.themePrimary.opacity(0.4), lineWidth: 0.3)
                )
                .padding(.top, 16)
                .padding(.leading, horizontalPadding)
                .zIndex(selectedDay == nil ? 1 : 0)
                .onTapGesture {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        showLast7Days.toggle()
                        selectedDay = nil
                    }
                }
                VStack(spacing: 0) {
                    ZStack(alignment: .bottom) {
                        gridLines(
                            in: size,
                            maxPlays: maxPlays,
                            horizontalPadding: horizontalPadding
                        )

                        HStack(alignment: .bottom, spacing: spacing) {
                            ForEach(data) { play in
                                bar(
                                    date: play.day,
                                    count: play.count,
                                    maxPlays: maxPlays,
                                    height: size.height - 80,
                                    width: actualBarWidth,
                                    isSelected: selectedDay == play.day
                                )
                                .onTapGesture {
                                    withAnimation(
                                        .spring(
                                            response: 0.3,
                                            dampingFraction: 0.7
                                        )
                                    ) {
                                        selectedDay =
                                            selectedDay == play.day
                                                ? nil : play.day
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, 40)
                        .padding(.bottom, 16)

                        if let selectedDay = selectedDay,
                           let play = data.first(where: {
                               calendar.isDate(
                                   $0.day,
                                   inSameDayAs: selectedDay
                               )
                           })
                        {
                            selectionPopup(for: play, in: size, data: data)
                        }
                    }
                }
            }
        }
    }

    private func formatDayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    @ViewBuilder
    private func gridLines(
        in size: CGSize,
        maxPlays _: CGFloat,
        horizontalPadding: CGFloat
    ) -> some View {
        let graphHeight = size.height - 60
        let lineCount = 4

        VStack(spacing: 0) {
            Spacer()
            ForEach(0 ..< lineCount, id: \.self) { index in
                if index > 0 {
                    Spacer()
                }
                Rectangle()
                    .fill(Color.primary.opacity(0.05))
                    .frame(height: 1)
            }
        }
        .frame(height: graphHeight)
        .padding(.horizontal, horizontalPadding)
        .padding(.bottom, 40)
    }

    @ViewBuilder
    private func bar(
        date _: Date,
        count: Int,
        maxPlays: CGFloat,
        height: CGFloat,
        width: CGFloat,
        isSelected: Bool
    ) -> some View {
        let hasData = count > 0
        let barHeight =
            hasData ? (CGFloat(count) / maxPlays) * height : height * 0.015
        let normalizedHeight = CGFloat(count) / maxPlays

        RoundedRectangle(cornerRadius: width * 0.25)
            .fill(
                barGradient(
                    hasData: hasData,
                    isSelected: isSelected,
                    normalizedHeight: normalizedHeight
                )
            )
            .frame(
                width: width * (isSelected ? 1.15 : 1.0),
                height: animateIn ? barHeight : 0
            )
            .opacity(isSelected ? 1.0 : hasData ? 0.85 : 0.3)
            .frame(width: width, height: height, alignment: .bottom)
    }

    private func barGradient(
        hasData: Bool,
        isSelected: Bool,
        normalizedHeight: CGFloat
    ) -> LinearGradient {
        if !hasData {
            return LinearGradient(
                colors: [
                    Color.themeAccent.opacity(0.15),
                    Color.themeAccent.opacity(0.1),
                ],
                startPoint: .bottom,
                endPoint: .top
            )
        }

        let intensity = 0.6 + (normalizedHeight * 0.4)

        return LinearGradient(
            colors: isSelected
                ? [Color.themeAccent.opacity(0.9), Color.themeAccent]
                : [
                    Color.themeAccent.opacity(intensity * 0.7),
                    Color.themeAccent.opacity(intensity),
                ],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    @ViewBuilder
    private func selectionPopup(
        for play: DailyPlayCount,
        in size: CGSize,
        data: [DailyPlayCount]
    )
        -> some View
    {
        let index =
            data.firstIndex(where: {
                calendar.isDate($0.day, inSameDayAs: play.day)
            }) ?? 0
        let barWidth = (size.width - 64) / CGFloat(data.count)
        let xPosition = 32 + (barWidth * CGFloat(index)) + (barWidth / 2)

        VStack(spacing: 4) {
            Text("\(play.count)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Color.themeAccent)

            Text(play.count == 1 ? "play" : "plays")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color.themePrimary.opacity(0.6))

            Text(formatDayLabel(play.day))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color.themePrimary.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.themeElement.opacity(0.95))
                .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 4)
        )
        .position(x: xPosition, y: 50)
        .transition(.scale.combined(with: .opacity))
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedDay = nil
            }
        }
    }
}
