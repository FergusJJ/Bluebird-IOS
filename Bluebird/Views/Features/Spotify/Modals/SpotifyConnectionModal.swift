import SwiftUI

struct SpotifyConnectionModal: View {
    @EnvironmentObject var appState: AppState
    @State private var isConnecting = false
    @State private var showDontAskMessage = false

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.themePrimary.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 12)

            // Close button
            HStack {
                Spacer()
                Button(action: {
                    appState.dismissSpotifyModal()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color.themePrimary.opacity(0.5))
                }
                .padding(.trailing, 16)
                .padding(.top, 8)
            }

            VStack(spacing: 20) {
                Image(systemName: "music.note.house.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.spotifyGreen)
                    .padding(.top, 8)

                VStack(spacing: 8) {
                    Text("Connect to Spotify")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.themePrimary)

                    Text("Connect your Spotify account to sync your music history and see real-time stats")
                        .font(.subheadline)
                        .foregroundColor(Color.themeSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Connect button
                if isConnecting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.themePrimary))
                        .padding(.vertical, 16)
                } else {
                    Button(action: {
                        initiateSpotifyConnection()
                    }) {
                        HStack {
                            Image(systemName: "link")
                            Text("Connect Spotify")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.spotifyGreen)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isConnecting)
                    .padding(.horizontal)
                }

                // Don't ask again button
                Button(action: {
                    appState.setDontAskAgainForSpotify()
                    showDontAskMessage = true

                    // Hide message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showDontAskMessage = false
                    }
                }) {
                    Text("Don't ask me again")
                        .font(.footnote)
                        .foregroundColor(Color.themeSecondary)
                        .underline()
                }
                .padding(.bottom, 20)
            }

            if showDontAskMessage {
                Text("You can connect Spotify anytime from Settings")
                    .font(.caption)
                    .foregroundColor(Color.themePrimary)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.themeElement)
                    .cornerRadius(8)
                    .transition(.opacity)
                    .padding(.bottom, 16)
            }
        }
        .background(Color.themeBackground)
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: -5)
    }

    private func initiateSpotifyConnection() {
        guard !isConnecting else { return }

        Task {
            isConnecting = true
            let success = await appState.connectSpotify()
            isConnecting = false
            if success {
                print("Spotify connection initiated from modal")
            }
        }
    }
}

// Helper for rounding specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
