import SwiftUI

struct ProfileHeadlineView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel

    @State var isEditing = false
    @State var editingBio = ""

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            HStack(spacing: 15) {
                ProfilePictureView()
                VStack(spacing: 15) {
                    Text(profileViewModel.username)
                        .font(.headline)
                        .foregroundStyle(Color.nearWhite)
                    if isEditing {
                        VStack(alignment: .trailing, spacing: 10) {
                            TextEditor(text: $editingBio)
                                .font(.subheadline)
                                .scrollContentBackground(.hidden)
                                .foregroundColor(Color.nearWhite)
                                .frame(minHeight: 50, maxHeight: 100)
                                .padding(5)
                                .background(Color.darkElement)
                                .cornerRadius(10)
                                .tint(Color.accentColor)

                            HStack(spacing: 20) {
                                Button("Discard") {
                                    withAnimation { isEditing = false }
                                }
                                .foregroundColor(Color.lightGray)

                                Button("Save") {
                                    Task {
                                        let success =
                                            await profileViewModel.updateUserBio(
                                                with: editingBio
                                            )
                                        if success {
                                            withAnimation { isEditing = false }
                                        }
                                    }
                                }
                                .foregroundColor(Color.babyBlue)
                                .bold()
                            }
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))

                    } else {
                        Text(
                            profileViewModel.bio.isEmpty
                                ? "Tap to add a bio" : profileViewModel.bio
                        )
                        .font(.subheadline)
                        .foregroundColor(
                            profileViewModel.bio.isEmpty
                                ? Color.lightGray : Color.nearWhite
                        )
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 5)
                        .onTapGesture {
                            editingBio = profileViewModel.bio
                            withAnimation {
                                isEditing = true
                            }
                        }
                    }
                }
            }
            Spacer()
            Text(profileViewModel.getCurrentlyPlayingHeadline())
                .font(.subheadline)
                .foregroundStyle(Color.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .center)
        .onAppear {
            Task {
                await profileViewModel.loadProfile()
                // maybe can use appState to store currently playing song
                // want to have it moving left to right showing the full name
            }
        }
    }
}
