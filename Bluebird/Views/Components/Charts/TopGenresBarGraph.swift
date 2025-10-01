import SwiftUI

struct TopGenresBarGraph: View {
    private let allGenres: GenreCounts
    @State private var animateIn = false
    @State private var selectedGenre: String? = nil

    private var displayGenres: [(genre: String, count: Int)] {
        let numGenres = 10
        let sorted = allGenres.sorted { $0.value > $1.value }
        return Array(
            sorted.prefix(numGenres).map { (genre: $0.key, count: $0.value) }
        )
    }

    init(allGenres: GenreCounts) {
        self.allGenres = allGenres
    }

    var body: some View {
        GeometryReader { geo in
            content(in: geo.size)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animateIn = true
            }
        }
    }

    @ViewBuilder
    private func content(in size: CGSize) -> some View {
        let data = displayGenres
        let maxCount = CGFloat(data.map { $0.count }.max() ?? 1)
        let verticalPadding: CGFloat = 16
        let horizontalPadding: CGFloat = 16
        let labelWidth: CGFloat = 90
        let availableHeight = size.height - (verticalPadding * 2)
        let barHeight = availableHeight / CGFloat(data.count)
        let spacing = barHeight * 0.15
        let actualBarHeight = barHeight - spacing
        let maxBarWidth = size.width - (horizontalPadding * 2) - labelWidth - 8

        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.darkElement.opacity(0.4))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)

                VStack(spacing: 0) {
                    ZStack(alignment: .leading) {
                        VStack(alignment: .leading, spacing: spacing) {
                            ForEach(data.indices, id: \.self) { index in
                                bar(
                                    genre: data[index].genre,
                                    count: data[index].count,
                                    maxCount: maxCount,
                                    maxWidth: maxBarWidth,
                                    height: actualBarHeight,
                                    labelWidth: labelWidth,
                                    isSelected: selectedGenre
                                        == data[index].genre
                                )
                                .onTapGesture {
                                    withAnimation(
                                        .spring(
                                            response: 0.3,
                                            dampingFraction: 0.7
                                        )
                                    ) {
                                        selectedGenre =
                                            selectedGenre == data[index].genre
                                                ? nil : data[index].genre
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.vertical, verticalPadding)

                        if let selectedGenre = selectedGenre,
                           let genreData = data.first(where: {
                               $0.genre == selectedGenre
                           })
                        {
                            selectionPopup(for: genreData, in: size, data: data)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func bar(
        genre: String,
        count: Int,
        maxCount: CGFloat,
        maxWidth: CGFloat,
        height: CGFloat,
        labelWidth: CGFloat,
        isSelected: Bool
    ) -> some View {
        let barWidth = (CGFloat(count) / maxCount) * maxWidth
        let normalizedWidth = CGFloat(count) / maxCount

        HStack(spacing: 8) {
            Text(genre)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.nearWhite.opacity(isSelected ? 1.0 : 0.7))
                .lineLimit(1)
                .frame(width: labelWidth, alignment: .leading)

            RoundedRectangle(cornerRadius: height * 0.25)
                .fill(
                    barColor(
                        isSelected: isSelected,
                        normalizedWidth: normalizedWidth
                    )
                )
                .frame(
                    width: animateIn ? barWidth : 0,
                    height: height * (isSelected ? 1.15 : 1.0)
                )
                .opacity(isSelected ? 1.0 : 0.85)
                .frame(maxWidth: maxWidth, alignment: .leading)
        }
        .frame(height: height)
    }

    private func barColor(
        isSelected: Bool,
        normalizedWidth _: CGFloat
    ) -> Color {
        return isSelected ? Color.babyBlue : Color.babyBlue.opacity(0.85)
    }

    @ViewBuilder
    private func selectionPopup(
        for genreData: (genre: String, count: Int),
        in size: CGSize,
        data: [(genre: String, count: Int)]
    ) -> some View {
        let index = data.firstIndex(where: { $0.genre == genreData.genre }) ?? 0
        let verticalPadding: CGFloat = 16
        let availableHeight = size.height - (verticalPadding * 2)
        let barHeight = availableHeight / CGFloat(data.count)
        let spacing = barHeight * 0.15
        let actualBarHeight = barHeight - spacing
        let yPosition =
            verticalPadding + (actualBarHeight + spacing) * CGFloat(index)
                + (actualBarHeight / 2)

        VStack(spacing: 4) {
            Text(genreData.genre)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color.nearWhite.opacity(0.8))
            HStack(spacing: 6) {
                Text("\(genreData.count)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color.babyBlue)

                Text(genreData.count == 1 ? "play" : "plays")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.nearWhite.opacity(0.6))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.darkElement.opacity(0.95))
                .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 4)
        )
        .position(x: size.width - 60, y: yPosition)
        .transition(.scale.combined(with: .opacity))
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedGenre = nil
            }
        }
    }
}
