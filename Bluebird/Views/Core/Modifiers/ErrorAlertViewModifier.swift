import SwiftUI

struct ErrorAlertViewModifier: ViewModifier {
    @EnvironmentObject var appState: AppState

    private var alertBinding: Binding<AppError?> {
        Binding<AppError?>(get: {
                                
                               if let error = appState.errorToDisplay, error.presentationStyle == .generic {
                                   return error
                               }
                               return nil
                           },
                           set: {
                               if $0 == nil {
                                   appState.clearError()
                               }

                           })
    }

    func body(content: Content) -> some View {
        content
            .alert(item: alertBinding) { presentationError in
                Alert(
                    title: Text("Error"),
                    message: Text(presentationError.localizedDescription),
                    dismissButton: .default(Text("OK")) {
                        print("Error alert closed")
                    }
                )
            }
    }
}
