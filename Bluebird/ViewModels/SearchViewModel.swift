import Combine
import Foundation

@MainActor
class SearchViewModel: ObservableObject {
    // MARK: ui status variables

    @Published var isSearchingSong = false

    // MARK: search inputs/outputs

    @Published var searchQuery: String = ""
    @Published var searchResults: [SongDetail] = []

    private var appState: AppState

    private let bluebirdAccountAPIService: BluebirdAccountAPIService
    private let supabaseManager = SupabaseClientManager.shared

    private var cancellables = Set<AnyCancellable>()
    private var searchSongTask: Task<Void, Never>?

    init(
        appState: AppState,
        bluebirdAccountAPIService: BluebirdAccountAPIService
    ) {
        self.appState = appState
        self.bluebirdAccountAPIService = bluebirdAccountAPIService
        setupSearchSongSubscription()
    }

    func searchSongs() async {
        let result = await bluebirdAccountAPIService.SearchSongs(
            query: searchQuery
        )
        switch result {
        case let .success(searchSongsResult):
            // let totalSongs = searchSongsResult.total
            // let sanitizedQuery = searchSongsResult.query
            searchResults = searchSongsResult.tracks
        case let .failure(serviceError):
            let presentationError = AppError(from: serviceError)
            print("Error searching for songs: \(presentationError)")
            appState.setError(presentationError)
        }
    }

    private func setupSearchSongSubscription() {
        $searchQuery
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.searchSongTask?.cancel()
                guard !searchQuery.isEmpty else {
                    print("empty")
                    self.updateSearchSongCheckState(isSearching: false)
                    self.clearSearchSongs()
                    return
                }
                self.updateSearchSongCheckState(isSearching: true)
                self.searchSongTask = Task {
                    await self.searchSongs()
                    if Task.isCancelled {
                        return
                    }
                    self.updateSearchSongCheckState(isSearching: false)
                }
            }.store(in: &cancellables)
    }

    private func clearSearchSongs() {
        searchResults.removeAll()
    }

    private func updateSearchSongCheckState(isSearching: Bool) {
        isSearchingSong = isSearching
    }
}
