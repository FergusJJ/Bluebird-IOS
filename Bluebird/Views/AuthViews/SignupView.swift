import SwiftUI

struct SignupView: View {
    @EnvironmentObject var appState: AppState

    @State private var isSigningUp = false
    @State private var errorMessage: String?

    var switchToLogin: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Login Page")

            Button("Sign Up") {
                errorMessage = nil
                isSigningUp = true
                Task {
                    defer { isSigningUp = false }
                    do {
                        try await appState.signUp()
                        print("Sign up complete")
                    } catch {
                        print("Sign up failed: \(error)")
                        errorMessage = "Sign up failed: \(error.localizedDescription)"
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSigningUp)
            if isSigningUp {
                ProgressView()
                    .padding(.top, 10)
            }
            Button("Already have an account? Switch to Login") {
                switchToLogin()
            }
            Spacer()
        }
    }
}
