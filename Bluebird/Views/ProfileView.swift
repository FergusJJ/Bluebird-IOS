import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel

    var body: some View {
        VStack {
            ProfileHeadlineView()
            Spacer()
        }
    }
}
