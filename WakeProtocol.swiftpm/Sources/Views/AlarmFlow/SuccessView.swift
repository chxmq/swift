import SwiftUI

/// Success screen — calm, rewarding completion after dismissing the alarm
struct SuccessView: View {
    let onDismiss: () -> Void
    var onSnooze: (() -> Void)?

    @State private var showContent = false
    @State private var showButton = false
    @State private var glowPulse = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            // Calm green glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.successAccent.opacity(0.1), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 250
                    )
                )
                .scaleEffect(glowPulse ? 1.3 : 1.0)
                .animation(
                    .easeInOut(duration: 3).repeatForever(autoreverses: true),
                    value: glowPulse
                )

            VStack(spacing: 0) {
                Spacer()

                if showContent {
                    // Checkmark
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(Theme.successAccent)
                        .padding(.bottom, 24)

                    Text("ALARM DISMISSED")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .tracking(4)
                        .foregroundStyle(Theme.successAccent)
                        .padding(.bottom, 8)

                    Text("Good morning")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(.white)
                        .padding(.bottom, 20)

                    Text(currentTime())
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .monospacedDigit()
                }

                Spacer()

                if showButton {
                    VStack(spacing: 12) {
                        // Snooze button
                        if let onSnooze {
                            Button {
                                HapticsManager.shared.mediumTap()
                                onSnooze()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "zzz")
                                        .font(.system(size: 12, weight: .bold))
                                    Text("SNOOZE 5 MIN")
                                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                        .tracking(2)
                                }
                                .foregroundStyle(Theme.warningAccent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Theme.warningAccent.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Theme.warningAccent.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }

                        // Done button
                        Button {
                            HapticsManager.shared.lightTap()
                            onDismiss()
                        } label: {
                            Text("DONE")
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .tracking(4)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Theme.successAccent.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Theme.successAccent.opacity(0.4), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 32)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer().frame(height: 50)
            }
        }
        .onAppear {
            glowPulse = true
            HapticsManager.shared.success()
            HapticsManager.shared.playSuccessSound()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { showContent = true }
            withAnimation(.easeOut(duration: 0.5).delay(1.0)) { showButton = true }
        }
        .accessibilityLabel("Alarm dismissed. Good morning.")
    }

    private func currentTime() -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: Date())
    }
}
