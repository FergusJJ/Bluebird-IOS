import SwiftUI
import Foundation

class BarDataPoint: Identifiable {
    let date: Date
    let value: Double
    
    var id: Date { date }
    
    init(date: Date, value: Double) {
        self.date = date
        self.value = value
    }
}

struct TimeSeriesBarGraph: View {
    let data: [BarDataPoint]
    let unitName: String
    let popupDateFormatter: (Date) -> String
    
    @State private var selectedDate: Date? = nil
    @State private var animateIn = false
    
    private let calendar = Calendar.current
    
    var body: some View {
        GeometryReader { geo in
            content(in: geo.size)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animateIn = true
            }
        }
        .onChange(of: data.map { $0.id }) { _, _ in
             selectedDate = nil
        }
    }
    
    @ViewBuilder
    private func content(in size: CGSize) -> some View {
        let maxValue = max(CGFloat(data.map { $0.value }.max() ?? 0), 1)
        let horizontalPadding: CGFloat = 32
        let availableWidth = size.width - (horizontalPadding * 2)
        let barWidth = availableWidth / CGFloat(data.count)
        let spacing = barWidth * 0.15
        let actualBarWidth = barWidth - spacing
        
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.themeElement.opacity(0.4))
                .shadow(color: .themeShadow, radius: 4, x: 0, y: 2)
            
            VStack(spacing: 0) {
                ZStack(alignment: .bottom) {
                    gridLines(
                        in: size,
                        maxValue: maxValue,
                        horizontalPadding: horizontalPadding
                    )
                    
                    HStack(alignment: .bottom, spacing: spacing) {
                        ForEach(data) { point in
                            bar(
                                value: point.value,
                                maxValue: maxValue,
                                height: size.height - 80,
                                width: actualBarWidth,
                                isSelected: selectedDate == point.date
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedDate = selectedDate == point.date ? nil : point.date
                                }
                            }
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, 40)
                    .padding(.bottom, 16)

                    if let selectedDate = selectedDate,
                       let point = data.first(where: { $0.date == selectedDate })
                    {
                        selectionPopup(for: point, in: size, data: data)
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews

    @ViewBuilder
    private func gridLines(
        in size: CGSize,
        maxValue: CGFloat,
        horizontalPadding: CGFloat
    ) -> some View {
        let graphHeight = size.height - 60
        let lineCount = 4
        
        VStack(spacing: 0) {
            Spacer()
            ForEach(0 ..< lineCount, id: \.self) { index in
                if index > 0 {
                    Spacer()
                }
                Rectangle()
                    .fill(Color.primary.opacity(0.05))
                    .frame(height: 1)
            }
        }
        .frame(height: graphHeight)
        .padding(.horizontal, horizontalPadding)
        .padding(.bottom, 40)
    }
    
    @ViewBuilder
    private func bar(
        value: Double,
        maxValue: CGFloat,
        height: CGFloat,
        width: CGFloat,
        isSelected: Bool
    ) -> some View {
        let hasData = value > 0
        let barHeight = hasData ? (CGFloat(value) / maxValue) * height : height * 0.015
        let normalizedHeight = CGFloat(value) / maxValue
        
        RoundedRectangle(cornerRadius: width * 0.25)
            .fill(
                barGradient(
                    hasData: hasData,
                    isSelected: isSelected,
                    normalizedHeight: normalizedHeight
                )
            )
            .frame(
                width: width * (isSelected ? 1.15 : 1.0),
                height: animateIn ? barHeight : 0
            )
            .opacity(isSelected ? 1.0 : hasData ? 0.85 : 0.3)
            .frame(width: width, height: height, alignment: .bottom)
    }
    
    @ViewBuilder
    private func selectionPopup(
        for point: BarDataPoint,
        in size: CGSize,
        data: [BarDataPoint]
    ) -> some View {
        let index = data.firstIndex(where: { $0.date == point.date }) ?? 0
        let barWidth = (size.width - 64) / CGFloat(data.count)
        let xPosition = 32 + (barWidth * CGFloat(index)) + (barWidth / 2)
        
        VStack(spacing: 4) {
            Text("\(Int(point.value))") 
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Color.themeAccent)
            
            Text(point.value == 1 ? unitName : "\(unitName)s")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color.themePrimary.opacity(0.6))
            
            Text(popupDateFormatter(point.date))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color.themePrimary.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.themeElement.opacity(0.95))
                .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 4)
        )
        .position(x: xPosition, y: 50)
        .transition(.scale.combined(with: .opacity))
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedDate = nil
            }
        }
    }
    
    // MARK: - Helpers

    private func barGradient(
        hasData: Bool,
        isSelected: Bool,
        normalizedHeight: CGFloat
    ) -> LinearGradient {
        if !hasData {
            return LinearGradient(
                colors: [Color.themeAccent.opacity(0.15), Color.themeAccent.opacity(0.1)],
                startPoint: .bottom, endPoint: .top
            )
        }
        
        let intensity = 0.6 + (normalizedHeight * 0.4)
        
        return LinearGradient(
            colors: isSelected
                ? [Color.themeAccent.opacity(0.9), Color.themeAccent]
                : [Color.themeAccent.opacity(intensity * 0.7), Color.themeAccent.opacity(intensity)],
            startPoint: .bottom, endPoint: .top
        )
    }
}
