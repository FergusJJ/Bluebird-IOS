import SwiftUI

struct AdaptiveTabBarModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .tabBar)
            .toolbarBackground(Color.themeBackground, for: .tabBar)
            .toolbarBackgroundVisibility(.visible, for: .tabBar)
    }
}

struct AdaptiveNavigationBarAppearance: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .onAppear {
                updateAppearance()
            }
            .onChange(of: colorScheme) { _, _ in
                updateAppearance()
            }
    }

    private func updateAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.themeBackground)
        appearance.shadowColor = .clear

        let textColor = UIColor(Color.themePrimary)
        appearance.titleTextAttributes = [.foregroundColor: textColor]
        appearance.largeTitleTextAttributes = [.foregroundColor: textColor]

        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [.foregroundColor: textColor]
        buttonAppearance.highlighted.titleTextAttributes = [.foregroundColor: textColor]
        appearance.buttonAppearance = buttonAppearance
        appearance.doneButtonAppearance = buttonAppearance
        appearance.backButtonAppearance = buttonAppearance

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().compactScrollEdgeAppearance = appearance

        UINavigationBar.appearance().tintColor = textColor
        UINavigationBar.appearance().isTranslucent = false
        UIBarButtonItem.appearance().tintColor = textColor
    }
}

extension View {
    func applyDefaultTabBarStyling() -> some View {
        modifier(AdaptiveTabBarModifier())
    }

    func applyAdaptiveNavigationBar() -> some View {
        modifier(AdaptiveNavigationBarAppearance())
    }
}
