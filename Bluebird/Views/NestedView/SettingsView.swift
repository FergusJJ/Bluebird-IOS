import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var appState: AppState // don't want to add method for updating theme rn so just adding here

    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Spotify Connection Details")
                        .font(.headline)
                        .foregroundColor(Color.themePrimary)
                    Picker("Theme", selection: $appState.userColorScheme) {
                        Text("System").tag(nil as ColorScheme?)
                        Text("Light").tag(ColorScheme.light as ColorScheme?)
                        Text("Dark").tag(ColorScheme.dark as ColorScheme?)
                    }
                    .pickerStyle(.segmented)
                }
                connectedDetail()
                Divider()

                Button {
                    Task {
                        await onLogoutProfile()
                    }
                } label: {
                    Text("Log Out")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.themeAccent)
                        .cornerRadius(10)
                }
                .padding(.top, 8)

                Button {
                    showDeleteConfirmation = true
                } label: {
                    Text("Delete Account")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding(.top, 8)
                .disabled(isDeleting)
            }
            .padding(.horizontal)
            .padding(.top)
        }
        .background(Color.themeBackground.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .applyDefaultTabBarStyling()
        .task {
            await profileViewModel.fetchConnectedSpotifyDetails()
        }

        .alert("Are you sure?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    await performDelete()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "This action is irreversible and will permanently delete your account."
            )
        }
    }

    @ViewBuilder
    private func connectedDetail() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spotify Connection Details")
                .font(.headline)
                .foregroundColor(Color.themePrimary)

            connectedDetailRow(
                heading: "Display Name",
                value: profileViewModel.connectedAccountDetails?.display_name
                    ?? "loading..."
            )
            connectedDetailRow(
                heading: "Spotify Account Email",
                value: profileViewModel.connectedAccountDetails?.email
                    ?? "loading..."
            )
            connectedDetailRow(
                heading: "Spotify User ID",
                value: profileViewModel.connectedAccountDetails?.spotify_user_id
                    ?? "loading..."
            )
            connectedDetailRow(
                heading: "Enabled Scopes",
                value: profileViewModel.connectedAccountDetails?.scopes
                    ?? "loading..."
            )
            connectedDetailRow(
                heading: "Spotify Account Link",
                value: profileViewModel.connectedAccountDetails?.account_url
                    ?? "loading..."
            )
            connectedDetailRow(
                heading: "Spotify Account Tier",
                value: profileViewModel.connectedAccountDetails?.product
                    ?? "loading..."
            )
        }
    }

    @ViewBuilder
    private func connectedDetailRow(heading: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(heading)
                .font(.caption)
                .foregroundColor(Color.themePrimary)

            if let url = URL(string: value),
               value.lowercased().hasPrefix("http")
            {
                Link(destination: url) {
                    Text(value)
                        .font(.caption)
                        .foregroundColor(Color.themeAccent)
                        .underline()
                }
            } else {
                Text(value)
                    .font(.caption)
                    .foregroundColor(Color.themePrimary.opacity(0.8))
            }
        }
    }

    func onLogoutProfile() async {
        await profileViewModel.logOut()
    }

    func performDelete() async {
        isDeleting = true
        await onDeleteProfile()
        isDeleting = false
    }

    func onDeleteProfile() async {
        await profileViewModel.deleteAccount()
    }
}
