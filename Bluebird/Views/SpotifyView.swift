import SwiftUI

struct SpotifyView: View {
    @EnvironmentObject var appState: AppState

    @State private var isConnecting = false
    @State private var connectionErrorMessage: String?
    @State private var showConnectionAlert = false

    @State private var logoutError: String?

    private func initiateSpotifyConnection() {
        guard !isConnecting else { return }

        Task {
            isConnecting = true
            connectionErrorMessage = nil
            showConnectionAlert = false

            let error = await appState.connectSpotify()

            isConnecting = false

            if let error = error {
                print("Error initiating Spotify connection: \(error.localizedDescription)")
                connectionErrorMessage = error.localizedDescription
                showConnectionAlert = true
            } else {
                print("Spotify connection initiation requested successfully.")
            }
        }
    }

    private func logOut() {
        showConnectionAlert = false
        logoutError = nil
        Task {
            let err = await appState.logoutUser()
            if err != nil {
                logoutError =
                    err?.localizedDescription ?? "An unknown error occurred during logout."
            }
        }
    }

    var body: some View {
        ZStack {
            Color.spotifyDarkGray
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Connect Spotify")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Please connect your Spotify account to continue.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)

                if isConnecting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.vertical)
                } else {
                    Button("Connect to Spotify") {
                        initiateSpotifyConnection()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.spotifyGreen)
                    .disabled(isConnecting)
                    .padding(.vertical)
                }

                if let logoutErr = logoutError {
                    Text("Logout failed: \(logoutErr)")
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding()
        }
        .alert("Connection Error", isPresented: $showConnectionAlert) {
            Button("Try Again", action: initiateSpotifyConnection)
            Button("Log out", role: .destructive, action: logOut)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                connectionErrorMessage
                    ?? "Unable to connect spotify to your account. Please try again.")
        }
    }
}
