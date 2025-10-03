import SwiftUI

struct CircleIconButton: View {
    let systemName: String
    let action: () -> Void

    // TODO: make look nice
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title2)
                .padding(10)
                .background(Color.themeBackground.opacity(0.7)) // might change this to be dark no matter what
                .clipShape(Circle())
                .foregroundStyle(.white)
                .shadow(radius: 4, y: 2)
        }
    }
}
