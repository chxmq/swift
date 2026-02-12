import SwiftUI

/// Learn tab — sleep science education with expandable cards
struct LearnView: View {
    @State private var expandedCard: Int?

    private let articles: [(icon: String, title: String, color: Color, body: String)] = [
        (
            "brain.head.profile",
            "What is Sleep Inertia?",
            Color(red: 0.4, green: 0.5, blue: 1.0),
            "Sleep inertia is the groggy, disoriented feeling you experience immediately after waking up. It occurs because your brain doesn't switch from sleep to wakefulness instantly — the transition takes 15 to 30 minutes.\n\nDuring this window, your prefrontal cortex (responsible for decision-making and self-control) is essentially still offline. That's why you can tap 'dismiss' on your alarm and fall right back asleep — your conscious brain wasn't even involved in the decision.\n\nResearch shows that sleep inertia is worse when you wake during deep (slow-wave) sleep, which is more common in the earlier hours of the morning."
        ),
        (
            "waveform.path",
            "Why Sound Alone Fails",
            Color(red: 1.0, green: 0.65, blue: 0.0),
            "Your brain is evolutionarily designed to habituate to repeated, predictable stimuli. This is called auditory habituation — after hearing the same alarm tone for a few days, your auditory cortex literally stops flagging it as important.\n\nThis is why changing your alarm tone every few weeks temporarily helps. But ultimately, any single-sense alarm will fail because:\n\n• Sound can be blocked (pillows, earplugs)\n• Your brain learns to ignore it over time\n• It doesn't require any cognitive engagement\n• You can dismiss it without true awareness\n\nEffective waking requires engaging multiple senses and forcing cognitive involvement."
        ),
        (
            "chart.bar.fill",
            "The Statistics",
            Color(red: 1.0, green: 0.3, blue: 0.3),
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
                    VStack(spacing: 14) {
                        ForEach(Array(articles.enumerated()), id: \.offset) { index, article in
                            articleCard(index: index, article: article)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Learn")
        }
    }

    @ViewBuilder
    private func articleCard(index: Int, article: (icon: String, title: String, color: Color, body: String)) -> some View {
        let isExpanded = expandedCard == index

        VStack(alignment: .leading, spacing: 0) {
            // Header (always visible)
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    expandedCard = isExpanded ? nil : index
                }
                HapticsManager.shared.lightTap()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: article.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(article.color)
                        .frame(width: 32)

                    Text(article.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(16)
            }
            .accessibilityLabel("\(article.title). \(isExpanded ? "Collapse" : "Expand")")

            // Body (expanded)
            if isExpanded {
                Rectangle()
                    .fill(article.color.opacity(0.2))
                    .frame(height: 1)
                    .padding(.horizontal, 16)

                Text(article.body)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textPrimary.opacity(0.85))
                    .lineSpacing(6)
                    .padding(16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isExpanded ? article.color.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
    }
}
