import Combine
import Foundation

@MainActor
class GenericSearchViewModel<T: Decodable & Hashable, V: Decodable>: ObservableObject {
    @Published var isSearching = false
    @Published var searchQuery = ""
    @Published var searchResults: [T] = []

    private var appState: AppState

    private let searchFunction: (String) async -> Result<V, BluebirdAPIError>
    private let unwrapFunction: (V) -> [T]

    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?

    private var debounceDuration: RunLoop.SchedulerTimeType.Stride

    init(
        debounceDuration: RunLoop.SchedulerTimeType.Stride = .milliseconds(500),
        appState: AppState,
        searchFunction: @escaping (String) async -> Result<V, BluebirdAPIError>,
        unwrapFunction: @escaping (V) -> [T]
    ) {
        self.debounceDuration = debounceDuration
        self.appState = appState
        self.searchFunction = searchFunction
        self.unwrapFunction = unwrapFunction
        setupSearchSubscription()
    }

    private func setupSearchSubscription() {
        $searchQuery
            .debounce(for: debounceDuration, scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.searchTask?.cancel()
                guard !searchQuery.isEmpty else {
                    self.updateSearchCheckState(newState: false)
                    self.clearSearchResults()
                    return
                }
                self.updateSearchCheckState(newState: true)
                self.searchTask = Task {
                    await self.doSearch()
                    if Task.isCancelled {
                        return
                    }
                    self.updateSearchCheckState(newState: false)
                }
            }.store(in: &cancellables)
    }

    func doSearch() async {
        let result = await searchFunction(searchQuery)
        switch result {
        case let .success(response):
            let items = unwrapFunction(response)
            searchResults = items
        case let .failure(serviceError):
            searchResults = []
            let presentationError = AppError(from: serviceError)
            appState.setError(presentationError)
        }
    }

    private func clearSearchResults() {
        searchResults.removeAll()
    }

    private func updateSearchCheckState(newState: Bool) {
        isSearching = newState
    }
}
