import SwiftUI

struct ErrorAlertViewModifier: ViewModifier {
    @EnvironmentObject var appState: AppState

    func body(content: Content) -> some View {
        content
            .alert(item: $appState.errorToDisplay) { presentationError in
                Alert(
                    title: Text("Error"),
                    message: Text(presentationError.localizedDescription),
                    dismissButton: .default(Text("OK")) {
                        print("Error alert dismissed.")
                    }
                )
            }
    }
}
