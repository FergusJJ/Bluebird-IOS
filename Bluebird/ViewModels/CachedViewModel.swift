import Foundation

@MainActor
protocol CachedViewModel: ObservableObject {
    var cacheManager: CacheManager { get }
}

extension CachedViewModel {

    // onUpdate: Closure to update ViewModel
    func fetchWithCache<T>(
        cacheGetter: () -> T?,
        apiFetch: () async -> T?,
        onUpdate: @escaping (T) -> Void,
        cacheSetter: @escaping (T) -> Void,
        forceRefresh: Bool = false
    ) async {
        if !forceRefresh, let cached = cacheGetter() {
            onUpdate(cached)
            return
        }
        guard let fresh = await apiFetch() else {
            return
        }
        onUpdate(fresh)
        cacheSetter(fresh)
    }

    // Same logic, tuple returns
    func fetchWithCache<T, U>(
        cacheGetter: () -> (T, U)?,
        apiFetch: () async -> (T, U)?,
        onUpdate: @escaping (T, U) -> Void,
        cacheSetter: @escaping (T, U) -> Void,
        forceRefresh: Bool = false
    ) async {
        if !forceRefresh, let cached = cacheGetter() {
            onUpdate(cached.0, cached.1)
            return
        }
        guard let fresh = await apiFetch() else {
            return
        }
        onUpdate(fresh.0, fresh.1)
        cacheSetter(fresh.0, fresh.1)
    }

    func fetchWithCacheArray<T>(
        cacheGetter: () -> [T],
        isCacheStale: () -> Bool,
        apiFetch: () async -> [T]?,
        onUpdate: @escaping ([T]) -> Void,
        cacheSetter: @escaping ([T]) -> Void,
        forceRefresh: Bool = false
    ) async {
        let cached = cacheGetter()
        if !forceRefresh, !cached.isEmpty, !isCacheStale() {
            onUpdate(cached)
            return
        }
        guard let fresh = await apiFetch() else {
            return
        }
        onUpdate(fresh)
        cacheSetter(fresh)
    }
}
