import SwiftUI

struct CircleIconButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title2)
                .padding(10)
                .background(Color.black.opacity(0.7))
                .clipShape(Circle())
                .foregroundStyle(.white)
                .shadow(radius: 4, y: 2)
        }
    }
}
