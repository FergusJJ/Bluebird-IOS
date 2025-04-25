import SwiftUI

struct ErrorAlertViewModifier: ViewModifier {
    @EnvironmentObject var appState: AppState

    func body(content: Content) -> some View {
        content
            .alert(item: $appState.errorToDisplay) { displayableError in
                Alert(
                    title: Text("Error"),
                    message: Text(displayableError.localizedDescription),
                    dismissButton: .default(Text("OK")) {
                        print("Error alert dismissed.")
                    }
                )
            }
    }
}
