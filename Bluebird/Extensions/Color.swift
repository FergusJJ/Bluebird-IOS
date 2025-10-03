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
        light: Color(red: 0.2, green: 0.5, blue: 0.8),
        dark: Color(red: 0.53, green: 0.81, blue: 0.92)
    )
    // Backgrounds
    static let themeBackground = Color(
        light: Color(red: 0.95, green: 0.95, blue: 0.97),
        dark: Color(red: 0.1, green: 0.1, blue: 0.15)
    )

    static let themeElement = Color(
        light: Color.white,
        dark: Color(red: 0.15, green: 0.15, blue: 0.20)
    )

    // Text colours
    static let themePrimary = Color(
        light: Color(red: 0.1, green: 0.1, blue: 0.1),
        dark: Color(red: 0.95, green: 0.95, blue: 0.96)
    )

    static let themeSecondary = Color(
        light: Color(red: 0.4, green: 0.4, blue: 0.45),
        dark: Color(red: 0.6, green: 0.6, blue: 0.65)
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
