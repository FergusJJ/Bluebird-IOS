import Foundation
import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case featureTour = 1
    case friends = 2
    case feed = 3

    var title: String {
        switch self {
        case .welcome:
            return "Welcome"
        case .featureTour:
            return "Explore"
        case .friends:
            return "Connect"
        case .feed:
            return "Discover"
        }
    }
}

@MainActor
class OnboardingManager: ObservableObject, TryRequestViewModel {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var isComplete: Bool = false

    @AppStorage("hasCompletedOnboardingLocally") private
        var hasCompletedLocally: Bool = false

    internal var appState: AppState
    private var apiService: BluebirdAccountAPIService

    init(appState: AppState, apiService: BluebirdAccountAPIService) {
        self.appState = appState
        self.apiService = apiService
    }

    var isFirstStep: Bool {
        currentStep == OnboardingStep.allCases.first
    }

    var isLastStep: Bool {
        currentStep == OnboardingStep.allCases.last
    }

    var progress: Double {
        let currentIndex = Double(currentStep.rawValue)
        let totalSteps = Double(OnboardingStep.allCases.count)
        return (currentIndex + 1) / totalSteps
    }

    func nextStep() {
        guard !isLastStep else {
            completeOnboarding()
            return
        }

        if let nextStepValue = OnboardingStep(
            rawValue: currentStep.rawValue + 1
        ) {
            withAnimation {
                currentStep = nextStepValue
            }
        }
    }

    func previousStep() {
        guard !isFirstStep else { return }

        if let previousStepValue = OnboardingStep(
            rawValue: currentStep.rawValue - 1
        ) {
            withAnimation {
                currentStep = previousStepValue
            }
        }
    }

    func skipOnboarding() {
        completeOnboarding()
    }

    func completeOnboarding() {
        isComplete = true
        hasCompletedLocally = true

        Task {
            await markOnboardingCompleteOnBackend()
        }
    }

    private func markOnboardingCompleteOnBackend() async {
        let result: Void? = await tryRequest(
            { await apiService.completeOnboarding() },
            "OnboardingManager: Failed to mark onboarding complete"
        )
        if result == nil {
            appState.hasCompletedOnboarding = true
            appState.shouldShowOnboarding = false
            return
        }

        print(
            "OnboardingManager: Successfully marked onboarding complete on backend"
        )
        appState.hasCompletedOnboarding = true
        appState.shouldShowOnboarding = false
    }

    func reset() {
        currentStep = .welcome
        isComplete = false
        hasCompletedLocally = false
    }
}
