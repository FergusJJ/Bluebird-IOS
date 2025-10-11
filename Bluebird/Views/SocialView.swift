import SwiftUI

struct SocialView: View {
    @State private var isSearching = false

    var body: some View {
        VStack(spacing: 0) {
            if isSearching {
                SearchbarView(isSearching: $isSearching)
                    .padding(.top, 10)
                    .transition(.move(edge: .top))
                    .zIndex(2)
            }

            ZStack {
                if isSearching {
                    // if searching and there are results, show list
                } else {
                    // otherwise show feed
                }
                if isSearching {
                    // if searching an there are no results, allow clicking out of
                    // the search view
                    Color.clear
                        .contentShape(Rectangle())
                        .ignoresSafeArea()
                        .onTapGesture {
                            isSearching = false
                            DispatchQueue.main.async {
                                UIApplication.shared.sendAction(
                                    #selector(UIResponder.resignFirstResponder),
                                    to: nil, from: nil, for: nil
                                )
                            }
                        }
                        .zIndex(1)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.themeBackground.ignoresSafeArea())
        .navigationTitle("Feed")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Image(systemName: "person.crop.badge.magnifyingglass.fill")
                    .foregroundColor(Color.themePrimary)
                    .onTapGesture {
                        withAnimation { isSearching.toggle() }
                    }
            }
        }
        .applyDefaultTabBarStyling()
    }
}
