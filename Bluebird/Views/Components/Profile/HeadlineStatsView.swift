import SwiftUI

struct HeadlineStatsView: View {
    let totalMinutesListened: Int
    let totalPlays: Int
    let totalUniqueArtists: Int

    var body: some View {
        HStack(spacing: 0) {
            StatItemView(
                value: formatMinutes(totalMinutesListened),
                label: "Minutes",
                icon: "clock.fill"
            )

            Divider()
                .frame(height: 40)
                .background(Color.themeSecondary.opacity(0.3))

            StatItemView(
                value: formatNumber(totalPlays),
                label: "Plays",
                icon: "play.fill"
            )

            Divider()
                .frame(height: 40)
                .background(Color.themeSecondary.opacity(0.3))

            StatItemView(
                value: formatNumber(totalUniqueArtists),
                label: "Artists",
                icon: "person.2.fill"
            )
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.themeElement)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.themeSecondary.opacity(0.1), lineWidth: 1)
        )
    }

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        } else {
            return "\(minutes)m"
        }
    }

    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            let thousands = Double(number) / 1000.0
            return String(format: "%.1fk", thousands)
        } else {
            return "\(number)"
        }
    }
}

struct StatItemView: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(Color.themeAccent)

                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.themePrimary)
            }

            Text(label)
                .font(.caption)
                .foregroundColor(Color.themeSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
