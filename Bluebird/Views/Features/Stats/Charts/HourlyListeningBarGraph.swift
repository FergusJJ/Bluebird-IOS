import SwiftUI

struct HourlyListeningBarGraph: View {
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

