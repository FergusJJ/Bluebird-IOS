import SwiftUI

struct DailyTrendBarGraph: View {
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
