import SwiftUI

struct SearchbarView<T: Decodable & Hashable, V: Decodable>: View {
    @EnvironmentObject var searchViewModel: GenericSearchViewModel<T, V>
    @FocusState private var isFocused: Bool

    @Binding var isSearching: Bool
    let placeholderText: String

    var body: some View {
        HStack(spacing: 15) {
            TextField(placeholderText, text: $searchViewModel.searchQuery)
                .keyboardType(.default)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding(12)
                .background(Color.themeElement)
                .cornerRadius(15)
                .foregroundColor(Color.themePrimary)
                .font(.system(size: 16))
                .focused($isFocused)
                .onChange(of: searchViewModel.searchQuery) { _, newValue in
                    if newValue.isEmpty && !isFocused {
                        isSearching = false
                    }
                }

            if searchViewModel.isSearching {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.themeAccent))
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 50)
        .cornerRadius(4)
        .shadow(radius: 5)
    }
}
