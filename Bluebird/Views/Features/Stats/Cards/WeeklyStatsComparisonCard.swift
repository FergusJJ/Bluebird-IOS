import SwiftUI

// not really a 'card' but don't jave better name right now
struct WeeklyStatsComparisonCard: View {
    let comparison: WeeklyPlatformComparison

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.themeElement.opacity(0.4))
                .overlay(
                    VStack {
                        LinearGradient(
                            colors: [
                                Color.themeHighlight.opacity(0.05),
                                Color.clear,
                            ],
                            startPoint: .top,
                            endPoint: .center
                        ).cornerRadius(20)
                    }
                )
                .shadow(
                    color: Color.themeShadow,
                    radius: 4,
                    x: 0,
                    y: 2
                )

            VStack(spacing: 16) {
                comparisonRow(
                    count: comparison.tracks,
                    entityType: "tracks",
                    percentile: comparison.tracks_percentile
                )

                Divider()
                    .background(Color.themePrimary.opacity(0.15))
                    .padding(.horizontal, 8)

                comparisonRow(
                    count: comparison.artists,
                    entityType: "artists",
                    percentile: comparison.artists_percentile
                )

                Divider()
                    .background(Color.themePrimary.opacity(0.15))
                    .padding(.horizontal, 8)

                comparisonRow(
                    count: comparison.albums,
                    entityType: "albums",
                    percentile: comparison.albums_percentile
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
    }

    @ViewBuilder
    private func comparisonRow(
        count: Int,
        entityType: String,
        percentile: Float64
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor(for: entityType).opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: iconName(for: entityType))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(iconColor(for: entityType))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(count)")
                        .font(
                            .system(size: 24, weight: .bold, design: .rounded)
                        )
                        .foregroundColor(Color.themePrimary)

                    Text(entityType)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.themePrimary.opacity(0.7))
                }

                HStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 10))
                        Text(
                            "\( count == 0 ? "More than 0%" :  String(format: "Top %.0f%%", 100 - percentile))"
                        )
                        .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(Color.themeAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.themeAccent.opacity(0.15))
                    )

                    Text("of all listeners")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.themePrimary.opacity(0.5))
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func iconName(for entityType: String) -> String {
        switch entityType {
        case "tracks":
            return "music.note"
        case "artists":
            return "music.mic"
        case "albums":
            return "square.stack.fill"
        default:
            return "music.note"
        }
    }

    private func iconColor(for entityType: String) -> Color {
        switch entityType {
        case "tracks":
            return Color.themeAccent
        case "artists":
            return Color.purple
        case "albums":
            return Color.green
        default:
            return Color.themeAccent
        }
    }
}
