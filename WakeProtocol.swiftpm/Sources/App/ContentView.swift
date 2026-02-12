import SwiftUI

/// App entry point — onboarding or main app
struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        if hasSeenOnboarding {
            MainTabView()
        } else {
            OnboardingView {
                withAnimation(.easeInOut(duration: 0.5)) {
                    hasSeenOnboarding = true
                }
            }
        }
    }
}

/// First-launch onboarding — 3 concise slides
struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var currentPage = 0

    private let pages: [(icon: String, title: String, subtitle: String, color: Color)] = [
        (
            "bell.badge.waveform.fill",
            "Smart Alarms",
            "Traditional alarms let you hit snooze.\nWake Protocol makes you prove you're awake.",
            Theme.primaryAccent
        ),
        (
            "brain.head.profile.fill",
            "Beat Sleep Inertia",
            "Cognitive challenges activate your\nprefrontal cortex — the part of your brain\nthat takes longest to wake up.",
            Theme.purpleAccent
        ),
        (
            "sparkles",
            "Ready to Wake Up?",
            "Create your first alarm and choose\na challenge that fits your style.",
            Theme.successAccent
        )
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button {
                            HapticsManager.shared.lightTap()
                            onComplete()
                        } label: {
                            Text("Skip")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .frame(height: 44)

                Spacer()

                // Content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        onboardingPage(page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                Spacer()

                // Dots + button
                VStack(spacing: 28) {
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage ? pages[currentPage].color : Theme.textTertiary)
                                .frame(width: index == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }

                    // Action button
                    Button {
                        HapticsManager.shared.lightTap()
                        if currentPage < pages.count - 1 {
                            withAnimation(.spring(response: 0.4)) {
                                currentPage += 1
                            }
                        } else {
                            onComplete()
                        }
                    } label: {
                        Text(currentPage < pages.count - 1 ? "NEXT" : "GET STARTED")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .tracking(3)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(pages[currentPage].color.opacity(0.25))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(pages[currentPage].color.opacity(0.5), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 60)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func onboardingPage(_ page: (icon: String, title: String, subtitle: String, color: Color)) -> some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [page.color.opacity(0.15), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 160, height: 160)

                Image(systemName: page.icon)
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(page.color)
            }

            Text(page.title)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)

            Text(page.subtitle)
                .font(.system(size: 15))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.horizontal, 32)
    }
}
