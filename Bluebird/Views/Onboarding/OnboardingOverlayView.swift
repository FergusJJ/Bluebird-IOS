import SwiftUI

struct OnboardingOverlayView: View {
    @EnvironmentObject var onboardingManager: OnboardingManager
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            // Main content card
            VStack(spacing: 0) {
                // Header with close/skip button
                HStack {
                    if !onboardingManager.isFirstStep {
                        Button(action: {
                            onboardingManager.previousStep()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20))
                                .foregroundColor(Color.themePrimary)
                        }
                        .padding(.leading, 16)
                    } else {
                        Spacer()
                            .frame(width: 52)
                    }

                    Spacer()

                    Button(action: {
                        onboardingManager.skipOnboarding()
                    }) {
                        Text("Skip")
                            .font(.subheadline)
                            .foregroundColor(Color.themeSecondary)
                    }
                    .padding(.trailing, 16)
                }
                .padding(.top, 16)

                // Progress indicator
                OnboardingProgressIndicator(
                    currentStep: onboardingManager.currentStep
                )
                .padding(.top, 12)

                // Step content
                ScrollView {
                    Group {
                        switch onboardingManager.currentStep {
                        case .welcome:
                            OnboardingWelcomeStep(
                                username: getUsernameForDisplay()
                            )
                        case .featureTour:
                            OnboardingFeatureTourStep()
                        case .friends:
                            OnboardingFriendsStep()
                        case .feed:
                            OnboardingFeedStep()
                        }
                    }
                }
                .frame(maxHeight: .infinity)

                // Navigation buttons
                HStack(spacing: 16) {
                    if onboardingManager.isLastStep {
                        Button(action: {
                            onboardingManager.completeOnboarding()
                        }) {
                            Text("Get Started")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.themePrimary)
                                .cornerRadius(12)
                        }
                    } else {
                        Button(action: {
                            onboardingManager.nextStep()
                        }) {
                            Text("Next")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.themePrimary)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .frame(maxHeight: 600)
            .background(Color.themeBackground)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 24)
        }
    }

    private func getUsernameForDisplay() -> String {
        // Try to get username from cache first
        if let userId = CacheManager.shared.getCurrentUserId(),
            let username = CacheManager.shared.getUserProfile(userId: userId)?
                .username
        {
            return username
        }
        // Fallback to email or "there"
        return "there"
    }
}
