import SwiftUI

/// About tab — personal story, app info, and credits
struct AboutView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // App brand header
                        brandHeader
                            .padding(.top, 20)

                        // Personal story
                        storySection

                        // How it works
                        howItWorksSection

                        // Credits
                        creditsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("About")
        }
    }

    // MARK: - Brand Header

    private var brandHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                // Glow ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.primaryAccent.opacity(0.15), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 110, height: 110)

                Circle()
                    .stroke(Theme.primaryAccent.opacity(0.2), lineWidth: 1)
                    .frame(width: 80, height: 80)

                Image(systemName: "bell.badge.waveform.fill")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(Theme.primaryAccent)
            }

            VStack(spacing: 6) {
                Text("WAKE PROTOCOL")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .tracking(4)
                    .foregroundStyle(.white)

                Text("Swift Student Challenge 2025")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textTertiary)

                Text("v1.0")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Theme.textTertiary.opacity(0.5))
            }
        }
    }

    // MARK: - Story

    private var storySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("MY STORY")

            VStack(alignment: .leading, spacing: 12) {
                Text("I built Wake Protocol because I have a real problem with alarms.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)

                Text("Every morning, the same cycle — alarm rings, I tap dismiss without thinking, and I fall back asleep. I've tried louder sounds, multiple alarms, putting my phone across the room. Nothing worked.")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textPrimary.opacity(0.8))

                Text("When I learned about sleep inertia — the neuroscience behind why this happens — I realized the problem isn't willpower. Your brain needs a cognitive challenge to actually activate.")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textPrimary.opacity(0.8))

                Text("Wake Protocol is my answer: an alarm that escalates and forces you to prove you're alert before it stops.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.primaryAccent.opacity(0.9))
            }
            .lineSpacing(4)
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.primaryAccent.opacity(0.08), lineWidth: 1)
            )
        }
    }

    // MARK: - How It Works

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("HOW IT WORKS")

            VStack(spacing: 10) {
                stepRow(number: "1", icon: "chart.line.uptrend.xyaxis", title: "Escalating Alert", desc: "3-phase system: standby → warning → critical", color: Theme.primaryAccent)
                stepRow(number: "2", icon: "hand.tap.fill", title: "Cognitive Challenge", desc: "Sequence, trace, or color matching puzzle", color: Theme.warningAccent)
                stepRow(number: "3", icon: "brain.head.profile.fill", title: "Cortex Activation", desc: "Proves your prefrontal cortex is online", color: Theme.successAccent)
            }
        }
    }

    private func stepRow(number: String, icon: String, title: String, desc: String, color: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.surface)
        )
    }

    // MARK: - Credits

    private var creditsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("BUILT WITH")

            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    techBadge("SwiftUI", icon: "swift")
                    techBadge("UIKit", icon: "iphone")
                    techBadge("UserNotifications", icon: "bell")
                }
                HStack(spacing: 10) {
                    techBadge("AudioToolbox", icon: "speaker.wave.2")
                    techBadge("Canvas API", icon: "paintbrush")
                }
            }

            VStack(spacing: 4) {
                Text("No third-party dependencies")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
                Text("100% Apple frameworks")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
    }

    private func techBadge(_ name: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(name)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
        }
        .foregroundStyle(Theme.primaryAccent.opacity(0.7))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Theme.primaryAccent.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Theme.primaryAccent.opacity(0.12), lineWidth: 1)
        )
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .tracking(3)
            .foregroundStyle(Theme.textTertiary)
    }
}
