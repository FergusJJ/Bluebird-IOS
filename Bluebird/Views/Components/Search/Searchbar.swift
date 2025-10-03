import SwiftUI

struct SearchbarView: View {
    @EnvironmentObject var searchViewModel: SearchViewModel
    @FocusState private var isFocused: Bool
    @Binding var isSearching: Bool

    var body: some View {
        HStack(spacing: 15) {
            TextField("Search Song", text: $searchViewModel.searchQuery)
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

            if searchViewModel.isSearchingSong {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.themeAccent))
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 50)
        .background(Color.themeBackground.opacity(0.8))
        .cornerRadius(4)
        .shadow(radius: 5)
    }
}
