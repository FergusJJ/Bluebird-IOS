import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var isLoggingIn = false
    @State private var errorMessage: String?

    var switchToSignup: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Login Page")

            Button("Log In") {
                errorMessage = nil
                isLoggingIn = true
                Task {
                    defer { isLoggingIn = false }
                    do {
                        try await appState.loginUser()
                        print("Log in complete")
                    } catch {
                        print("Log in failed: \(error)")
                        errorMessage = "Log in failed: \(error.localizedDescription)"
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoggingIn)
            if isLoggingIn {
                ProgressView()
                    .padding(.top, 10)
            }
            Button("Don't have an account? Sign Up") {
                switchToSignup()
            }
            Spacer()
        }
    }
}
