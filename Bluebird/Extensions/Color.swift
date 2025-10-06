import SwiftUI

extension Color {
    init(light: Color, dark: Color) {
        self.init(
            UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(dark) : UIColor(light)
            }
        )
    }

    // Primary accent
    static let themeAccent = Color(
        light: Color(red: 0.25, green: 0.45, blue: 0.95),
        dark: Color(red: 0.53, green: 0.81, blue: 0.92)
    )
    // Backgrounds
    static let themeBackground = Color(
        light: Color(red: 0.98, green: 0.97, blue: 0.95),
        dark: Color(red: 0.1, green: 0.1, blue: 0.15)
    )

    static let themeElement = Color(
        light: Color(red: 0.97, green: 0.96, blue: 0.94),
        dark: Color(red: 0.15, green: 0.15, blue: 0.20)
    )

    // Text colours
    static let themePrimary = Color(
        light: Color(red: 0.08, green: 0.08, blue: 0.12),
        dark: Color(red: 0.95, green: 0.95, blue: 0.96)
    )

    static let themeSecondary = Color(
        light: Color(red: 0.35, green: 0.35, blue: 0.42),
        dark: Color(red: 0.6, green: 0.6, blue: 0.65)
    )
    static let themeShadow = Color(
        light: Color(red: 0.2, green: 0.3, blue: 0.5).opacity(0.15),
        dark: Color.black.opacity(0.4)
    )

    static let themeHighlight = Color(
        light: Color.white.opacity(0.8),
        dark: Color.white.opacity(0.05)
    )
    // Self explainatory
    static let spotifyDarkGray = Color(
        red: 18 / 255,
        green: 18 / 255,
        blue: 18 / 255
    )
    static let spotifyGreen = Color(
        red: 30 / 255,
        green: 215 / 255,
        blue: 96 / 255
    )
}
