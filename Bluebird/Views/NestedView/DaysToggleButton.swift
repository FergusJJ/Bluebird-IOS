import SwiftUI

struct DaysToggleButton: View {
    @Binding var forDays: Int

    var body: some View {
        HStack {
            Text(daysLabel())
                .font(.system(size: 14, weight: .semibold))
            Image(systemName: "arrow.left.arrow.right.circle")
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundColor(.nearWhite)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.darkElement.opacity(0.8))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.nearWhite.opacity(0.4), lineWidth: 0.3)
        )
        .onTapGesture {
            cycleDays()
        }
    }

    private func cycleDays() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            switch forDays {
            case 0: forDays = 7
            case 7: forDays = 14
            case 14: forDays = 30
            case 30: forDays = 0
            default: forDays = 0
            }
        }
    }

    private func daysLabel() -> String {
        switch forDays {
        case 0: return "All Time"
        case 7: return "Last 7 Days"
        case 14: return "Last 14 Days"
        case 30: return "Last 30 Days"
        default: return "All Time"
        }
    }
}
