import SwiftUI

/// Learn tab — sleep science education with expandable cards
struct LearnView: View {
    @State private var expandedCard: Int?
    @State private var insightsExpanded = false
    @State private var healthService = SleepHealthService.shared
    private let wakeStore = WakeHistoryStore.shared

    private let articles: [(icon: String, title: String, color: Color, body: String)] = [
        (
            "brain.head.profile",
            "What is Sleep Inertia?",
            Theme.oliveLeaf,
            "Sleep inertia is the groggy, disoriented feeling you experience immediately after waking up. It occurs because your brain doesn't switch from sleep to wakefulness instantly — the transition takes 15 to 30 minutes.\n\nDuring this window, your prefrontal cortex (responsible for decision-making and self-control) is essentially still offline. That's why you can tap 'dismiss' on your alarm and fall right back asleep — your conscious brain wasn't even involved in the decision.\n\nResearch shows that sleep inertia is worse when you wake during deep (slow-wave) sleep, which is more common in the earlier hours of the morning."
        ),
        (
            "waveform.path",
            "Why Sound Alone Fails",
            Theme.lightCaramel,
            "Your brain is evolutionarily designed to habituate to repeated, predictable stimuli. This is called auditory habituation — after hearing the same alarm tone for a few days, your auditory cortex literally stops flagging it as important.\n\nThis is why changing your alarm tone every few weeks temporarily helps. But ultimately, any single-sense alarm will fail because:\n\n• Sound can be blocked (pillows, earplugs)\n• Your brain learns to ignore it over time\n• It doesn't require any cognitive engagement\n• You can dismiss it without true awareness\n\nEffective waking requires engaging multiple senses and forcing cognitive involvement."
        ),
        (
            "chart.bar.fill",
            "The Statistics",
            Theme.copper,
            "The numbers tell a clear story:\n\n• 57% of young adults hit snooze at least once every morning\n• The average person spends 3.5 months of their lifetime hitting snooze\n• Students who regularly oversleep report 30% lower academic performance\n• Sleep inertia impairs cognitive function by up to 51%\n• Over 80% of people report their alarm is ineffective at actually waking them up\n\nOversleeping isn't laziness — it's a design problem. Traditional alarms weren't built with neuroscience in mind."
        ),
        (
            "sparkles",
            "How Wake Protocol Works",
            Theme.primaryAccent,
            "Wake Protocol addresses the root cause: your brain needs to be genuinely engaged before it can stay awake. Here's how:\n\n1. Escalating Alerts — Instead of one constant sound, the alarm intensifies through three phases (Standby → Warning → Critical), preventing habituation.\n\n2. Multi-Sensory Feedback — Combines visual alerts, haptic vibrations, and sound. Multiple senses are harder for your brain to ignore.\n\n3. Cognitive Challenge — Before you can dismiss the alarm, you must complete a task that requires real attention: tapping a sequence, tracing a pattern, or matching colors.\n\n4. Forced Activation — These challenges specifically engage your prefrontal cortex, the part of your brain that sleep inertia keeps offline."
        )
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
                        insightsCard

                        VStack(alignment: .leading, spacing: 10) {
                            Text("THE SCIENCE")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .tracking(2)
                                .foregroundStyle(Theme.textSecondary)

                            VStack(spacing: Theme.cardSpacing) {
                                ForEach(Array(articles.enumerated()), id: \.offset) { index, article in
                                    articleCard(index: index, article: article)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Theme.innerPadding)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await healthService.fetchSleepData()
            }
        }
    }

    // MARK: - Sleep Insights Card

    private var insightsCard: some View {
        let health = healthService
        let wake = wakeStore
        let isExpanded = insightsExpanded
        let useHealth = health.isAvailable && health.authorizationStatus == .sharingAuthorized && health.hasEnoughData
        let insights: [SleepInsight] = useHealth ? health.insights() : wake.insights()
        let hasInsights = useHealth || wake.hasEnoughData
        let showConnectHealth = health.isAvailable && health.authorizationStatus != .sharingAuthorized
        let healthUnavailable = !health.isAvailable

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    insightsExpanded.toggle()
                }
                HapticsManager.shared.lightTap()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.successAccent)
                        .frame(width: 28, height: 28)

                    Text("Your Sleep Insights")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)

                    if hasInsights {
                        Text("\(insights.count)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.successAccent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.successAccent.opacity(0.2))
                            .clipShape(Capsule())
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(Theme.innerPadding)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Your Sleep Insights. \(isExpanded ? "Collapse" : "Expand")")

            if isExpanded {
                Rectangle()
                    .fill(Theme.successAccent.opacity(0.2))
                    .frame(height: 1)
                    .padding(.horizontal, Theme.innerPadding)

                if health.isLoading {
                    HStack(spacing: 10) {
                        ProgressView()
                            .tint(Theme.successAccent)
                        Text("Loading sleep data…")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Theme.innerPadding)
                    .transition(.opacity)
                } else if hasInsights {
                    VStack(alignment: .leading, spacing: 12) {
                        if useHealth {
                            Text("From Apple Health")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        ForEach(insights) { insight in
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(Theme.successAccent.opacity(0.3))
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 6)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(insight.title)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(Theme.textSecondary)
                                    Text(insight.value)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(Theme.textPrimary)
                                    if let detail = insight.detail {
                                        Text(detail)
                                            .font(.system(size: 12))
                                            .foregroundStyle(Theme.textSecondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(Theme.innerPadding)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                } else if healthUnavailable {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Apple Health is not available in Simulator.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                        Text("On a real device, you can connect Health for sleep insights. Here, complete at least 2 alarms in the last 14 days to see insights from your wake times instead.")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textSecondary)
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(Theme.innerPadding)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                } else if showConnectHealth {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Connect Apple Health to see sleep duration, bedtime consistency, weekday vs weekend patterns, and more — all from your actual sleep data.")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textPrimary)
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)

                        if let err = healthService.lastError {
                            Text(err)
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.dangerAccent)
                        }

                        Button {
                            HapticsManager.shared.lightTap()
                            Task { await healthService.requestAuthorization() }
                        } label: {
                            HStack(spacing: 8) {
                                if healthService.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 14))
                                }
                                Text(healthService.isLoading ? "Requesting…" : "Connect Apple Health")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Theme.primaryAccent)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(healthService.isLoading)
                    }
                    .padding(Theme.innerPadding)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    Text("Complete at least 2 alarms in the last 14 days to see your personalized insights.\n\nYour wake times help you understand your sleep patterns — consistency, weekday vs weekend differences, and more.")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textPrimary)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(Theme.innerPadding)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(
                    isExpanded ? Theme.successAccent.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
    }

    @ViewBuilder
    private func articleCard(index: Int, article: (icon: String, title: String, color: Color, body: String)) -> some View {
        let isExpanded = expandedCard == index

        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    expandedCard = isExpanded ? nil : index
                }
                HapticsManager.shared.lightTap()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: article.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(article.color)
                        .frame(width: 28, height: 28)

                    Text(article.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(Theme.innerPadding)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(article.title). \(isExpanded ? "Collapse" : "Expand")")

            if isExpanded {
                Rectangle()
                    .fill(article.color.opacity(0.2))
                    .frame(height: 1)
                    .padding(.horizontal, Theme.innerPadding)

                VStack(alignment: .leading, spacing: 16) {
                    ForEach(paragraphs(article.body), id: \.self) { paragraph in
                        Text(paragraph)
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.textPrimary)
                            .lineSpacing(10)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.innerPadding)
                .padding(.bottom, 4)
                .transition(.opacity)
            }
        }
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(
                    isExpanded ? article.color.opacity(0.35) : Color.clear,
                    lineWidth: 1
                )
        )
    }

    private func paragraphs(_ body: String) -> [String] {
        body.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
