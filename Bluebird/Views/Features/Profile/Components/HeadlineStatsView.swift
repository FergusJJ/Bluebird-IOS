import SwiftUI

struct HeadlineStatsView: View {
    let totalMinutesListened: Int
    let totalPlays: Int
    let totalUniqueArtists: Int
    let friendCount: Int
    var onFriendsTap: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 8) {
            // Top row - Minutes and Plays
            HStack(spacing: 8) {
                CompactStatView(
                    value: formatMinutes(totalMinutesListened),
                    label: "Minutes",
                    icon: "clock.fill",
                    accentColor: Color.themeAccent
                )

                CompactStatView(
                    value: formatNumber(totalPlays),
                    label: "Plays",
                    icon: "play.circle.fill",
                    accentColor: Color.green
                )
            }

            // Bottom row - Artists and Friends
            HStack(spacing: 8) {
                CompactStatView(
                    value: formatNumber(totalUniqueArtists),
                    label: "Artists",
                    icon: "music.mic",
                    accentColor: Color.purple
                )

                if let onFriendsTap = onFriendsTap {
                    Button(action: onFriendsTap) {
                        CompactStatView(
                            value: formatNumber(friendCount),
                            label: "Friends",
                            icon: "person.2.fill",
                            accentColor: Color.blue
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    CompactStatView(
                        value: formatNumber(friendCount),
                        label: "Friends",
                        icon: "person.2.fill",
                        accentColor: Color.blue
                    )
                }
            }
        }
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

struct CompactStatView: View {
    let value: String
    let label: String
    let icon: String
    let accentColor: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(accentColor)
                .frame(width: 32, height: 32)
                .background(accentColor.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.themePrimary)

                Text(label)
                    .font(.caption)
                    .foregroundColor(Color.themeSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color.themeElement)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.themeHighlight.opacity(0.1), lineWidth: 1)
        )
    }
}
