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

    private func connectLater() {
        appState.isInitialSignup = false
        appState.isSpotifyConnected = .isfalse
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
                Spacer()

                Image(systemName: "music.note.house.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.spotifyGreen)
                    .padding(.bottom, 10)

                Text("Connect Spotify")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Connect your Spotify account to start tracking your music history and discover insights")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)

                if isConnecting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.vertical, 30)
                } else {
                    VStack(spacing: 16) {
                        Button(action: initiateSpotifyConnection) {
                            HStack {
                                Image(systemName: "link")
                                Text("Connect to Spotify")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.spotifyGreen)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isConnecting)
                        .padding(.horizontal, 30)

                        if appState.isInitialSignup {
                            Button(action: connectLater) {
                                Text("Connect Later")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .underline()
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.vertical, 20)
                }

                if let logoutErr = appState.errorToDisplay?.localizedDescription {
                    Text("Logout failed: \(logoutErr)")
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()
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
