import Foundation

struct DisplayableError: Identifiable, Equatable {
    let id = UUID()
    let underlyingError: Error

    var localizedDescription: String {
        underlyingError.localizedDescription
    }

    static func == (lhs: DisplayableError, rhs: DisplayableError) -> Bool {
        lhs.id == rhs.id
    }
}
