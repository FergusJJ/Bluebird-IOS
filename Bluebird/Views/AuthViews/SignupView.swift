import SwiftUI

struct SignupView: View {
    @StateObject var viewModel: AuthViewModel
    // just for direct access to errors
    @ObservedObject var appState: AppState

    var switchToLogin: () -> Void

    private var isSignupDisabled: Bool {
        viewModel.isActionPending || viewModel.username.isEmpty || viewModel.email.isEmpty
            || viewModel.password.isEmpty || viewModel.usernameAvailable == false
    }

    init(switchToLogin: @escaping () -> Void, appState: AppState) {
        self.switchToLogin = switchToLogin
        _viewModel = StateObject(wrappedValue: AuthViewModel(appState: appState))
        self.appState = appState
    }

    var body: some View {
        ZStack {
            Color.spotifyDarkGray
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    Spacer()

                    Image(systemName: "bird.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(Color.themeAccent)
                    Text("Create Bluebird Account")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.themeAccent)

                    VStack(spacing: 15) {
                        TextField("Email", text: $viewModel.email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 5) {
                            TextField("Username", text: $viewModel.username)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                            HStack {
                                if viewModel.isCheckingUsername {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                    Text("Checking availability...")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                } else if let message = viewModel.usernameValidationMessage {
                                    Image(
                                        systemName: viewModel.usernameAvailable == true
                                            ? "checkmark.circle.fill" : "xmark.circle.fill"
                                    )
                                    .foregroundColor(
                                        viewModel.usernameAvailable == true ? .green : .red)
                                    Text(message)
                                        .font(.caption)
                                        .foregroundColor(
                                            viewModel.usernameAvailable == true ? .green : .red)
                                }
                                Spacer()
                            }
                            .frame(height: 20)
                        }
                        .padding(.horizontal)

                        SecureField("Password", text: $viewModel.password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                    }
                    .padding(.vertical)

                    if let errorMsg = appState.errorToDisplay?.localizedDescription {
                        Text(errorMsg)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Button {
                        Task {
                            await viewModel.signUp()
                        }
                    } label: {
                        if viewModel.isActionPending {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(height: 20)
                        } else {
                            Text("Sign Up")
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.themeAccent)
                    .foregroundColor(Color.spotifyDarkGray)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .disabled(isSignupDisabled)

                    Button("Already have an account? Log In") {
                        viewModel.email = ""
                        viewModel.username = ""
                        viewModel.password = ""
                        appState.clearError()
                        viewModel.usernameAvailable = nil
                        viewModel.usernameValidationMessage = nil
                        switchToLogin()
                    }
                    .foregroundColor(Color.themeAccent)
                    .padding(.top)

                    Spacer()
                    Spacer()
                }
                .padding()
                // .frame(minHeight: UIScreen.main.bounds.height)
            }
            .ignoresSafeArea(.keyboard)
        }
    }
}
