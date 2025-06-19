import Combine
import Foundation

@MainActor
class AuthViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isActionPending = false

    // might want to change this and use AppState.errorToDisplay instead?
    // would require changing appState signup/login functions to set the error
    // as it doesn't currently set one before returning it
    @Published var errorMessage: String?

    @Published var isCheckingUsername: Bool = false
    @Published var usernameAvailable: Bool?
    @Published var usernameValidationMessage: String?

    private let minUsernameLength = 3
    private var appState: AppState
    private var cancellables = Set<AnyCancellable>()
    private var usernameCheckTask: Task<Void, Never>?

    init(appState: AppState) {
        self.appState = appState
        setupUsernameCheckSubscription()
    }

    // @MainActor
    func login() async {
        errorMessage = nil
        isActionPending = true
        defer { isActionPending = false }

        let err = await appState.loginUser(
            email: email,
            password: password
        )

        if err != nil {
            errorMessage = err?.localizedDescription
        }
    }

    // FUTURE TODO: switch in appState.signUp to provide more finegrained error?
    // @MainActor
    func signUp() async {
        errorMessage = nil
        isActionPending = true
        defer { isActionPending = false }

        let err = await appState.signUp(
            email: email,
            username: username,
            password: password
        )

        if err != nil {
            errorMessage = err?.localizedDescription
        }
    }

    private func setupUsernameCheckSubscription() {
        $username
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] currentUsername in
                guard let self = self else { return }

                self.usernameCheckTask?.cancel()

                guard !currentUsername.isEmpty else {
                    self.updateUsernameCheckState(isChecking: false, isAvailable: nil, message: nil)
                    return
                }

                guard currentUsername.count >= self.minUsernameLength else {
                    self.updateUsernameCheckState(
                        isChecking: false,
                        isAvailable: false,
                        message: "Username must be at least \(self.minUsernameLength) characters."
                    )
                    return
                }

                self.updateUsernameCheckState(isChecking: true, isAvailable: nil, message: nil)

                self.usernameCheckTask = Task {
                    let isAvailable = await self.performUsernameAvailabilityCheck(
                        username: currentUsername)
                    if Task.isCancelled { return }
                    // await MainActor.run {
                    self.updateUsernameCheckState(
                        isChecking: false,
                        isAvailable: isAvailable,
                        message: isAvailable ? "Username available!" : "Username taken."
                    )
                    // }
                }
            }
            .store(in: &cancellables)
    }

    private func updateUsernameCheckState(isChecking: Bool, isAvailable: Bool?, message: String?) {
        isCheckingUsername = isChecking
        usernameAvailable = isAvailable
        usernameValidationMessage = message
    }

    private func performUsernameAvailabilityCheck(username: String) async -> Bool {
        do {
            let usernameResponse = try await SupabaseClientManager.shared.client
                .from("profiles")
                .select(count: .exact)
                .eq("username", value: username)
                .execute()
            guard (200 ..< 300).contains(usernameResponse.status) else {
                throw BluebirdAPIError.apiError(statusCode: usernameResponse.status, message: usernameResponse.string())
            }
            let count = usernameResponse.count ?? 0
            if count == 0 {
                return true
            }
            return false
        } catch {
            // network error?
            print("Error checking username availability: \(error)")
            return false
        }
    }

    deinit {
        print("AuthViewModel deinitialized")
        // Cancel all subscriptions and tasks on deinit
        cancellables.forEach { $0.cancel() }
        usernameCheckTask?.cancel()
    }
}
