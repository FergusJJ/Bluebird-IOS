import SwiftUI

struct DarkTabBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbarColorScheme(.dark, for: .tabBar)
            .toolbarBackground(Color.darkBackground, for: .tabBar)
            .toolbarBackgroundVisibility(.visible, for: .tabBar)
    }
}

struct DarkNavigationBarAppearance: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor(Color.darkBackground)
                appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

                let buttonAppearance = UIBarButtonItemAppearance()
                buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
                buttonAppearance.highlighted.titleTextAttributes = [.foregroundColor: UIColor.white]
                appearance.buttonAppearance = buttonAppearance
                appearance.doneButtonAppearance = buttonAppearance
                appearance.backButtonAppearance = buttonAppearance

                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                UINavigationBar.appearance().compactAppearance = appearance

                UINavigationBar.appearance().tintColor = UIColor.white
                UIBarButtonItem.appearance().tintColor = UIColor.white
            }
    }
}

extension View {
    func applyDefaultTabBarStyling() -> some View {
        modifier(DarkTabBarModifier())
    }

    func applyDarkNavigationBar() -> some View {
        modifier(DarkNavigationBarAppearance())
    }
}
