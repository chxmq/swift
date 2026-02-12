import SwiftUI

/// Core alarm experience — escalates through 3 visual phases until user must override
struct AlarmDemoView: View {
    let onTriggerChallenge: () -> Void
    var soundType: Int = 0

    @State private var phase: AlarmPhase = .standby
    @State private var timeElapsed: Double = 0
    @State private var pulseAmount: CGFloat = 1.0
    @State private var ringCycle: Double = 0
    @State private var shakeOffset: CGFloat = 0
    @State private var showOverride = false
    @State private var flashBorder = false

    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    // MARK: - Alarm phases with escalating intensity
    enum AlarmPhase {
        case standby, warning, critical

        var color: Color {
            switch self {
            case .standby: return Color(red: 0.0, green: 0.85, blue: 1.0)
            case .warning:  return Color(red: 1.0, green: 0.65, blue: 0.0)
            case .critical: return Color(red: 1.0, green: 0.15, blue: 0.15)
            }
        }
        var label: String {
            switch self {
            case .standby: return "STANDBY"
            case .warning:  return "WARNING"
            case .critical: return "CRITICAL"
            }
        }
        var pulseSpeed: Double {
            switch self {
            case .standby: return 2.0
            case .warning:  return 1.0
            case .critical: return 0.35
            }
        }
    }

    var body: some View {
        ZStack {
            // Phase-colored radial background
            RadialGradient(
                colors: [phase.color.opacity(0.25), Theme.background],
                center: .center,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            // Floating particles
            ParticleView(
                color: phase.color,
                intensity: phase == .critical ? 1.0 : (phase == .warning ? 0.6 : 0.3)
            )
            .ignoresSafeArea()

            // Expanding radar rings
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(phase.color.opacity(0.25 - Double(i) * 0.07), lineWidth: 1.5)
                    .scaleEffect(expandedRing(index: i))
                    .opacity(ringOpacity(index: i))
            }



            // Flashing border in critical
            if phase == .critical {
                RoundedRectangle(cornerRadius: 0)
                    .stroke(phase.color.opacity(flashBorder ? 0.6 : 0), lineWidth: 4)
                    .ignoresSafeArea()
            }

            VStack(spacing: 28) {
                // Phase label
                Text(phase.label)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .tracking(8)
                    .foregroundStyle(phase.color)

                // Central orb
                ZStack {
                    Circle()
                        .fill(phase.color.opacity(0.08))
                        .frame(width: 200, height: 200)
                        .scaleEffect(pulseAmount)

                    Circle()
                        .fill(phase.color.opacity(0.15))
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulseAmount * 0.95)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [phase.color, phase.color.opacity(0.4)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 45
                            )
                        )
                        .frame(width: 90, height: 90)
                        .shadow(color: phase.color.opacity(0.7), radius: 30)
                }

                // Current time
                Text(currentTime())
                    .font(.system(size: 60, weight: .ultraLight, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()

                // Phase dots
                HStack(spacing: 12) {
                    phaseDot(label: "LOW", active: true, color: Theme.primaryAccent)
                    phaseDot(label: "MED", active: phase != .standby, color: Theme.warningAccent)
                    phaseDot(label: "HIGH", active: phase == .critical, color: Theme.dangerAccent)
                }

                // Override button
                if showOverride {
                    Button(action: {
                        AlarmSoundManager.shared.stop()
                        timer.upstream.connect().cancel()
                        onTriggerChallenge()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 14))
                            Text("OVERRIDE REQUIRED")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(phase.color.opacity(0.25))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(phase.color, lineWidth: 1)
                        )
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .offset(x: shakeOffset)
        }
        .onReceive(timer) { _ in
            timeElapsed += 0.05
            updatePhase()
            updateAnimations()
        }
    }

    // MARK: - Phase progression
    private func updatePhase() {
        let sound = AlarmSoundManager.SoundType(rawValue: soundType) ?? .radar
        if timeElapsed > 6 && phase != .critical {
            withAnimation(.easeInOut(duration: 0.4)) { phase = .critical }
            HapticsManager.shared.heavyTap()
            AlarmSoundManager.shared.stop()
            AlarmSoundManager.shared.startAlarm(sound, intensity: 2)
        } else if timeElapsed > 3 && phase == .standby {
            withAnimation(.easeInOut(duration: 0.4)) { phase = .warning }
            HapticsManager.shared.warning()
            AlarmSoundManager.shared.startAlarm(sound, intensity: 1)
        }
        if timeElapsed > 8 && !showOverride {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { showOverride = true }
            HapticsManager.shared.rigidTap()
        }
    }

    // MARK: - Continuous animations driven by timer
    private func updateAnimations() {
        let speed = phase.pulseSpeed
        pulseAmount = 1.0 + CGFloat(0.08 * sin(timeElapsed * .pi * 2 / speed))

        let cycle = timeElapsed.truncatingRemainder(dividingBy: 2.5) / 2.5
        ringCycle = cycle

        if phase == .critical {
            shakeOffset = CGFloat.random(in: -3...3)
            flashBorder.toggle()
            // Periodic haptic pulse every ~0.5s during critical
            if Int(timeElapsed * 20) % 10 == 0 {
                HapticsManager.shared.rigidTap()
            }
        } else if phase == .warning {
            shakeOffset = 0
            // Softer periodic pulse every ~1s during warning
            if Int(timeElapsed * 20) % 20 == 0 {
                HapticsManager.shared.lightTap()
            }
        } else {
            shakeOffset = 0
        }
    }

    private func expandedRing(index: Int) -> CGFloat {
        let base = ringCycle + Double(index) * 0.25
        let clamped = base.truncatingRemainder(dividingBy: 1.0)
        return CGFloat(0.6 + clamped * 1.2)
    }
    private func ringOpacity(index: Int) -> Double {
        let base = ringCycle + Double(index) * 0.25
        let clamped = base.truncatingRemainder(dividingBy: 1.0)
        return 1.0 - clamped
    }

    // MARK: - Helpers
    private func currentTime() -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: Date())
    }

    @ViewBuilder
    private func phaseDot(label: String, active: Bool, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(active ? color : color.opacity(0.2))
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(active ? color : color.opacity(0.3))
        }
    }
}
