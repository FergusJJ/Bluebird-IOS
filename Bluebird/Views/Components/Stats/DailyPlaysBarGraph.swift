import SwiftUI

struct DailyPlaysBarGraph: View {
    let dailyPlays: [DailyPlay]
    @State private var selectedDay: Int? = nil
    @State private var animateIn = false

    private let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

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
        let maxPlays = max(
            CGFloat(dailyPlays.map { max($0.this_week, $0.last_week) }.max() ?? 0),
            1
        )
        let horizontalPadding: CGFloat = 32
        let availableWidth = size.width - (horizontalPadding * 2)
        let barWidth = availableWidth / CGFloat(dailyPlays.count)
        let spacing = barWidth * 0.3
        let actualBarWidth = barWidth - spacing

        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.darkElement.opacity(0.4))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)

                VStack(spacing: 0) {
                    ZStack(alignment: .bottom) {
                        gridLines(in: size, maxPlays: maxPlays, horizontalPadding: horizontalPadding)

                        HStack(alignment: .bottom, spacing: spacing) {
                            ForEach(dailyPlays.indices, id: \.self) { index in
                                let play = dailyPlays[index]
                                barPair(
                                    day: play.day_of_week,
                                    thisWeek: play.this_week,
                                    lastWeek: play.last_week,
                                    maxPlays: maxPlays,
                                    height: size.height - 80,
                                    width: actualBarWidth,
                                    isSelected: selectedDay == play.day_of_week
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedDay = selectedDay == play.day_of_week ? nil : play.day_of_week
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                        if let selectedDay = selectedDay,
                           let play = dailyPlays.first(where: { $0.day_of_week == selectedDay })
                        {
                            selectionPopup(for: play, in: size)
                        }
                    }
                    HStack(alignment: .center, spacing: spacing) {
                        ForEach(dailyPlays.indices, id: \.self) { index in
                            Text(dayLabels[index % 7])
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.nearWhite.opacity(0.4))
                                .frame(width: actualBarWidth)
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, 16)
                }
            }
        }
    }

    @ViewBuilder
    private func gridLines(in size: CGSize, maxPlays _: CGFloat, horizontalPadding: CGFloat) -> some View {
        let graphHeight = size.height - 60
        let lineCount = 4

        VStack(spacing: 0) {
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
    private func barPair(
        day _: Int,
        thisWeek: Int,
        lastWeek: Int,
        maxPlays: CGFloat,
        height: CGFloat,
        width: CGFloat,
        isSelected: Bool
    ) -> some View {
        let thisWeekHeight = (CGFloat(thisWeek) / maxPlays) * height
        let lastWeekHeight = (CGFloat(lastWeek) / maxPlays) * height

        ZStack(alignment: .bottom) {
            // last week
            RoundedRectangle(cornerRadius: width * 0.25)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.babyBlue.opacity(0.15),
                            Color.babyBlue.opacity(0.25),
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(width: width, height: animateIn ? lastWeekHeight : 0)
                .opacity(isSelected ? 0.4 : 0.3)
            // this week
            RoundedRectangle(cornerRadius: width * 0.25)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.babyBlue.opacity(0.7),
                            Color.babyBlue,
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(width: width * (isSelected ? 1.1 : 1.0), height: animateIn ? thisWeekHeight : 0)
                .opacity(isSelected ? 1.0 : 0.85)
        }
        .frame(width: width, height: height, alignment: .bottom)
    }

    @ViewBuilder
    private func selectionPopup(for play: DailyPlay, in size: CGSize) -> some View {
        let index = dailyPlays.firstIndex(where: { $0.day_of_week == play.day_of_week }) ?? 0
        let barWidth = (size.width - 80) / CGFloat(dailyPlays.count)
        let xPosition = 40 + (barWidth * CGFloat(index)) + (barWidth / 2)

        VStack(spacing: 4) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("This week")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.nearWhite.opacity(0.6))
                    Text("\(play.this_week)")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.babyBlue)
                }

                Rectangle()
                    .fill(Color.nearWhite.opacity(0.2))
                    .frame(width: 1, height: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Last week")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.nearWhite.opacity(0.6))
                    Text("\(play.last_week)")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.nearWhite.opacity(0.7))
                }
            }

            Text(dayLabels[index % 7])
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color.nearWhite.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.darkElement.opacity(0.95))
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
