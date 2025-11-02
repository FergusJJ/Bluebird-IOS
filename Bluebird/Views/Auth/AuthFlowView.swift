import SwiftUI

struct AuthFlowView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLoginScreen: Bool = true

    var body: some View {
        if showLoginScreen {
            LoginView(
                switchToSignup: {
                    withAnimation {
                        showLoginScreen = false
                    }
                }, appState: appState
            )
        } else {
            SignupView(
                switchToLogin: {
                    withAnimation {
                        showLoginScreen = true
                    }
                },
                appState: appState
            )
        }
    }
}
