import SwiftUI

struct AuthFlowView: View {
    @State private var showLoginScreen: Bool = true

    var body: some View {
        if showLoginScreen {
            LoginView(switchToSignup: {
                withAnimation {
                    showLoginScreen = false
                }
            })
        } else {
            SignupView(switchToLogin: {
                withAnimation {
                    showLoginScreen = true
                }
            })
        }
    }
}
