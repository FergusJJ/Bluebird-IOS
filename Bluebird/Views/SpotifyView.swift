import SwiftUI

struct SpotifyView: View {
    @EnvironmentObject var appState: AppState

    @State private var isConnecting = false
    @State private var showConnectionAlert = false

    private func initiateSpotifyConnection() {
        guard !isConnecting else { return }

        Task {
            isConnecting = true
            showConnectionAlert = false

            let success = await appState.connectSpotify()
            isConnecting = false
            if !success {
                showConnectionAlert = true
            } else {
                print("Spotify connection initiation requested successfully.")
            }
        }
    }

    private func logOut() {
        showConnectionAlert = false
        Task {
            let success = await appState.logoutUser()
            if !success {
                showConnectionAlert = true
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

                if let logoutErr = appState.errorToDisplay?.localizedDescription {
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
                appState.errorToDisplay?.localizedDescription
                    ?? "Unable to connect spotify to your account. Please try again.")
        }
    }
}
