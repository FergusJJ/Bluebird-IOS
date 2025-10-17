import SwiftUI

struct LeaderboardView: View {
    let leaderboard: LeaderboardResponse?
    @State private var selectedScope: LeaderboardScope = .global

    let type: LeaderboardType
    let id: String
    let onScopeChange: (LeaderboardScope) async -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Toggle for Platform/Friends
            ScopeToggle(selectedScope: $selectedScope)
                .onChange(of: selectedScope) { _, newScope in
                    Task {
                        await onScopeChange(newScope)
                    }
                }

            if let data = leaderboard {
                VStack(spacing: 12) {
                    // Top 3 leaderboard entries
                    ForEach(Array(data.leaderboard.prefix(3).enumerated()), id: \.offset) { index, entry in
                        LeaderboardRowView(
                            position: index + 1,
                            entry: entry,
                            isCurrentUser: false
                        )
                    }

                    // Current user row (always shown)
                    LeaderboardRowView(
                        position: nil, // Position shown in header
                        entry: data.current_user,
                        isCurrentUser: true
                    )
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Scope Toggle

struct ScopeToggle: View {
    @Binding var selectedScope: LeaderboardScope

    var body: some View {
        HStack(spacing: 0) {
            ToggleButton(
                title: "Platform",
                isSelected: selectedScope == .global,
                position: .left
            ) {
                selectedScope = .global
            }

            Divider()
                .background(Color.themeSecondary.opacity(0.3))

            ToggleButton(
                title: "Friends",
                isSelected: selectedScope == .friends,
                position: .right
            ) {
                selectedScope = .friends
            }
        }
        .frame(height: 36)
        .background(Color.themeBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.themeSecondary.opacity(0.2), lineWidth: 1)
        )
    }

    enum Position {
        case left, right
    }

    struct ToggleButton: View {
        let title: String
        let isSelected: Bool
        let position: Position
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? Color.themePrimary : Color.themeSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        isSelected ? Color.themeElement : Color.clear
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Leaderboard Row

struct LeaderboardRowView: View {
    let position: Int?
    let entry: LeaderboardEntry
    let isCurrentUser: Bool

    private var borderColor: Color {
        if isCurrentUser {
            return Color.themeAccent
        }

        guard let pos = position else { return Color.clear }

        switch pos {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0.0) // Gold
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75) // Silver
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2) // Bronze
        default: return Color.themeSecondary.opacity(0.3)
        }
    }

    private var gradientColors: [Color] {
        if isCurrentUser {
            return [
                Color.themeAccent.opacity(0.2),
                Color.themeAccent.opacity(0.05),
                Color.clear,
            ]
        }

    

        let baseColor = borderColor
        return [
            baseColor.opacity(0.2),
            baseColor.opacity(0.1),
            baseColor.opacity(0.05),
            Color.clear,
        ]
    }

    private var positionText: String {
        if isCurrentUser {
            return "Your Position"
        }

        guard let pos = position else { return "" }

        switch pos {
        case 1: return "1st Place"
        case 2: return "2nd Place"
        case 3: return "3rd Place"
        default: return "#\(pos)"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with position
            HStack(spacing: 8) {
                Text(positionText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isCurrentUser ? Color.themeAccent : borderColor)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(
                LinearGradient(
                    colors: gradientColors.map { $0.opacity(0.5) },
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )

            // Content row
            HStack(spacing: 12) {
                // Profile picture
                ZStack {
                    if !entry.profile.avatar_url.isEmpty, let url = URL(string: entry.profile.avatar_url) {
                        CachedAsyncImage(url: url)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .resizable()
                            .padding(8)
                            .foregroundColor(Color.themePrimary)
                            .background(Color.themeBackground.opacity(0.4))
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    }

                    if isCurrentUser {
                        Circle()
                            .stroke(Color.themeAccent, lineWidth: 2)
                            .frame(width: 40, height: 40)
                    }
                }

                // Username
                Text(entry.profile.username)
                    .font(.subheadline)
                    .fontWeight(isCurrentUser ? .semibold : .medium)
                    .foregroundColor(Color.themePrimary)
                    .lineLimit(1)

                Spacer()

                // Play count
                Text("\(entry.play_count)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.themeSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(
            HStack(spacing: 0) {
                // Left border
                Rectangle()
                    .fill(borderColor)
                    .frame(width: 4)

                // Gradient background
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        )
        .background(Color.themeElement)
        .cornerRadius(8)
    }
}
