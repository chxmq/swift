import SwiftUI

/// Countdown screen — builds suspense before alarm triggers
struct CountdownView: View {
    let onComplete: () -> Void

    @State private var count = 3
    @State private var countScale: CGFloat = 1.0
    @State private var ringProgress: CGFloat = 0
    @State private var showLabel = false

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            // Progress ring
            Circle()
                .stroke(Theme.primaryAccent.opacity(0.15), lineWidth: 2)
                .frame(width: 200, height: 200)

            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(Theme.primaryAccent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 24) {
                if showLabel {
                    Text("ALARM STARTING")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .tracking(6)
                        .foregroundStyle(Theme.primaryAccent)
                        .transition(.opacity)
                }

                Text("\(count)")
                    .font(.system(size: 96, weight: .ultraLight, design: .rounded))
                    .foregroundStyle(.white)
                    .scaleEffect(countScale)
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Text("GET READY")
                    .font(Theme.captionFont)
                    .tracking(3)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { showLabel = true }
        }
        .onReceive(timer) { _ in
            if count > 1 {
                HapticsManager.shared.mediumTap()
                HapticsManager.shared.playTickSound()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    count -= 1
                    countScale = 1.2
                }
                withAnimation(.linear(duration: 1)) {
                    ringProgress = CGFloat(3 - count) / 3.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.2)) { countScale = 1.0 }
                }
            } else {
                HapticsManager.shared.heavyTap()
                HapticsManager.shared.playAlarmSound()
                timer.upstream.connect().cancel()
                onComplete()
            }
        }
        .accessibilityLabel("Alarm starting in \(count) seconds")
    }
}
