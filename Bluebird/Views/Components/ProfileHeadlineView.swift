import SwiftUI

struct ProfileHeadlineView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel

    @State var isEditing = false
    @State var editingBio = ""

    var body: some View {
        VStack(spacing: 15) {
            ProfilePictureView()
            Text(profileViewModel.username)
                .font(.headline)
                .foregroundStyle(Color.nearWhite)

            if isEditing {
                VStack(alignment: .trailing, spacing: 10) {
                    TextEditor(text: $editingBio)
                        .font(.subheadline)
                        .scrollContentBackground(.hidden)
                        .foregroundColor(Color.nearWhite)
                        .frame(minHeight: 50)
                        .padding(5)
                        .background(Color.darkElement)
                        .cornerRadius(10)
                        .tint(Color.babyBlue)

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
                .fixedSize(horizontal: false, vertical: true)
                .transition(.move(edge: .top).combined(with: .opacity))

            } else {
                Text(profileViewModel.bio.isEmpty ? "Tap to add a bio" : profileViewModel.bio)
                    .font(.subheadline)
                    .foregroundColor(
                        profileViewModel.bio.isEmpty ? Color.lightGray : Color.nearWhite
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
        }.padding()
            .frame(maxWidth: .infinity, alignment: .center)
            .background(Color.darkBackground)
            .onAppear {
                Task {
                    await profileViewModel.loadProfile()
                }
            }
    }
}
