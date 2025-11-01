import SwiftUI

struct HourlyPlaysMinutesBarGraph: View {
    let hourlyPlaysMinutes: [Int]
    private let calendar = Calendar.current

    private var displayData: [BarDataPoint] {
        // get the date for the current hour  13:30 -> 13:00
        guard
            let currentHourDate = calendar.date(
                from: calendar.dateComponents(
                    [.year, .month, .day, .hour],
                    from: Date()
                )
            )
        else {
            return []
        }
        guard
            let startDate = calendar.date(
                byAdding: .hour,
                value: -23,
                to: currentHourDate
            )
        else {
            return []
        }

        var result: [BarDataPoint] = []
        for (index, minutes) in hourlyPlaysMinutes.enumerated() {
            if let date = calendar.date(
                byAdding: .hour,
                value: index,
                to: startDate
            ) {
                result.append(BarDataPoint(date: date, value: Double(minutes)))
            }
        }
        print(result.count)
        // just incase
        if result.count < 24 {
            for i in result.count..<24 {
                if let date = calendar.date(
                    byAdding: .hour,
                    value: i,
                    to: startDate
                ) {
                    result.append(BarDataPoint(date: date, value: 0))
                }
            }
        }

        return result
    }

    /// Formatter for the popup (e.g., "1PM", "12AM")
    private func formatHourLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter.string(from: date)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            TimeSeriesBarGraph(
                data: displayData,
                unitName: "minute",
                popupDateFormatter: formatHourLabel
            )
        }
    }
}

struct TrackTrendBarGraph: View {
    let trackTrend: [DailyPlayCount]
    @State private var showLast7Days = false
    private let calendar = Calendar.current
    private var displayData: [BarDataPoint] {
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

        var result: [BarDataPoint] = []
        var currentDate = startDate

        while currentDate <= endDate {
            let value: Double
            if let existing = trackTrend.first(where: {
                calendar.isDate($0.day, inSameDayAs: currentDate)
            }) {
                value = Double(existing.count)
            } else {
                value = 0
            }
            result.append(BarDataPoint(date: currentDate, value: value))

            currentDate = calendar.date(
                byAdding: .day,
                value: 1,
                to: currentDate
            )!
        }
        return result
    }

    private var title: String {
        showLast7Days ? "Last 7 Days" : "Last 30 Days"
    }

    private func formatDayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            TimeSeriesBarGraph(
                data: displayData,
                unitName: "play",
                popupDateFormatter: formatDayLabel
            )
            // this can probably be replaced with a DaysToggleButton
            HStack {
                Text(title)
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
            .padding(.leading, 32)
            .onTapGesture {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showLast7Days.toggle()
                }
            }
        }
    }
}
