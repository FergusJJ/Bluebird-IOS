import SwiftUI

struct OnboardingProgressIndicator: View {
    let currentStep: OnboardingStep
    let totalSteps: Int = OnboardingStep.allCases.count

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Circle()
                    .fill(index <= currentStep.rawValue ? Color.themePrimary : Color.themeSecondary.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }
}
