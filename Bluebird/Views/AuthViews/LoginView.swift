import SwiftUI

struct LoginView: View {
    @StateObject var viewModel: AuthViewModel

    var switchToSignup: () -> Void

    init(switchToSignup: @escaping () -> Void, appState: AppState) {
        self.switchToSignup = switchToSignup
        _viewModel = StateObject(wrappedValue: AuthViewModel(appState: appState))
    }

    var body: some View {
        ZStack {
            Color.darkBackground
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                // logo is placeholder
                Image(systemName: "bird.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(Color.babyBlue)

                Text("Bluebird")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.babyBlue)

                VStack(spacing: 15) {
                    TextField("Email", text: $viewModel.email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding(.horizontal)

                    SecureField("Password", text: $viewModel.password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                }
                .padding(.vertical)

                if let errorMsg = viewModel.errorMessage {
                    Text(errorMsg)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    Task {
                        await viewModel.login()
                    }
                } label: {
                    if viewModel.isActionPending {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(height: 20)
                    } else {
                        Text("Log In")
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.babyBlue)
                .foregroundColor(Color.darkBackground)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .cornerRadius(10)
                .padding(.horizontal)
                .disabled(
                    viewModel.isActionPending || viewModel.email.isEmpty
                        || viewModel.password.isEmpty)

                Button("Don't have an account? Sign Up") {
                    viewModel.email = ""
                    viewModel.password = ""
                    viewModel.errorMessage = nil
                    switchToSignup()
                }
                .foregroundColor(Color.babyBlue)
                .padding(.top)

                Spacer()
                Spacer()
            }
            .padding()
        }
    }
}
