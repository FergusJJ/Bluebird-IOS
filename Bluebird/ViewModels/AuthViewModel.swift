import Combine
import Foundation

@MainActor
class AuthViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isActionPending = false

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

    func login() async {
        isActionPending = true
        defer { isActionPending = false }

        let success = await appState.loginUser(
            email: email,
            password: password
        )
        if success {
            print("Login successful")
        }
    }

    // FUTURE TODO: switch in appState.signUp to provide more finegrained error?
    func signUp() async {
        isActionPending = true
        defer { isActionPending = false }

        let success = await appState.signUp(
            email: email,
            username: username,
            password: password
        )
        if success {
            print("Signup successful")
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
                    let isAvailableOrError = await self.performUsernameAvailabilityCheck(
                        username: currentUsername)
                    if Task.isCancelled { return }
                    guard let isAvailable = isAvailableOrError else {
                        self.updateUsernameCheckState(
                            isChecking: false,
                            isAvailable: nil,
                            message: "Unable to veridy username availability. Please try again later."
                        )
                        return
                    }
                    self.updateUsernameCheckState(
                        isChecking: false,
                        isAvailable: isAvailable,
                        message: isAvailable ? "Username available!" : "Username taken."
                    )
                }
            }
            .store(in: &cancellables)
    }

    private func updateUsernameCheckState(isChecking: Bool, isAvailable: Bool?, message: String?) {
        isCheckingUsername = isChecking
        usernameAvailable = isAvailable
        usernameValidationMessage = message
    }

    private func performUsernameAvailabilityCheck(username: String) async -> Bool? {
        let profileTable = "profiles"
        do {
            let usernameResponse = try await SupabaseClientManager.shared.client
                .from(profileTable)
                .select(count: .exact)
                .eq("username", value: username)
                .execute()
            guard (200 ..< 300).contains(usernameResponse.status) else {
                throw SupabaseError.unacceptableStatusCode(usernameResponse.status)
            }
            let count = usernameResponse.count ?? 0
            return count == 0
        } catch {
            print("Error checking username availability: \(error)")
            let presentationError: AppError
            if let supabaseError = error as? SupabaseError {
                presentationError = AppError(from: supabaseError)
            } else {
                let genericSupabaseError = SupabaseError.genericError(error)
                presentationError = AppError(from: genericSupabaseError)
            }
            appState.setError(presentationError)
            return nil
        }
    }

    deinit {
        print("AuthViewModel deinitialized")
        // Cancel all subscriptions and tasks on deinit
        cancellables.forEach { $0.cancel() }
        usernameCheckTask?.cancel()
    }
}
