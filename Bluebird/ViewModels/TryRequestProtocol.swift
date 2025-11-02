import Foundation

@MainActor
protocol TryRequestViewModel: ObservableObject {
    var appState: AppState { get }
}

extension TryRequestViewModel {
    func tryRequest<T>(
        _ call: () async -> Result<T, BluebirdAPIError>,
        _ perrorPrefix: String? = nil
    ) async -> T? {

        let result = await call()

        switch result {
        case .success(let data):
            return data

        case .failure(let serviceError):
            if case .requestCancelled = serviceError {
                print("[WARNING] The request was cancelled.")
            } else {
                let presentationError = AppError(from: serviceError)
                let printErrorPrefix = perrorPrefix ?? "API Error"

                print(
                    "\(printErrorPrefix): \(presentationError.localizedDescription)"
                )
                appState.setError(presentationError)
            }
            return nil
        }
    }
}
