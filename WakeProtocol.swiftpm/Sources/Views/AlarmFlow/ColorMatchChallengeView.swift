import SwiftUI

/// Color match challenge — rapidly tap circles matching the target color
struct ColorMatchChallengeView: View {
    let onComplete: () -> Void

    @State private var targetColorIndex = 0
    @State private var circles: [ColorCircle] = []
    @State private var score = 0
    @State private var wrongFlash = false
    @State private var completed = false
    @State private var timeRemaining: Double = 15
    @State private var hasGenerated = false

    private let requiredScore = 5
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    private let palette: [(name: String, color: Color)] = [
        ("CYAN", Color(red: 0.0, green: 0.85, blue: 1.0)),
        ("AMBER", Color(red: 1.0, green: 0.65, blue: 0.0)),
        ("VIOLET", Color(red: 0.6, green: 0.3, blue: 1.0)),
        ("JADE", Color(red: 0.0, green: 0.85, blue: 0.5)),
    ]

    struct ColorCircle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var colorIndex: Int
        var isHit = false
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                RadialGradient(
                    colors: [Theme.dangerAccent.opacity(0.12), Theme.background],
                    center: .center,
                    startRadius: 0,
                    endRadius: 400
                )
                .ignoresSafeArea()

                // Header
                VStack {
                    VStack(spacing: 8) {
                        Text("OVERRIDE REQUIRED")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .tracking(4)
                            .foregroundStyle(Theme.dangerAccent)

                        HStack(spacing: 4) {
                            Text("TAP ALL")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .tracking(2)
                                .foregroundStyle(Theme.textSecondary)

                            Text(palette[targetColorIndex].name)
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .tracking(2)
                                .foregroundStyle(palette[targetColorIndex].color)

                            Text("CIRCLES")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .tracking(2)
                                .foregroundStyle(Theme.textSecondary)
                        }

                        // Progress bar
                        HStack(spacing: 4) {
                            ForEach(0..<requiredScore, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(i < score ? Theme.successAccent : Theme.textTertiary)
                                    .frame(height: 4)
                            }
                        }
                        .frame(maxWidth: 260)
                        .padding(.top, 8)

                        // Timer bar
                        GeometryReader { barGeo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Theme.surface)
                                    .frame(height: 3)

                                RoundedRectangle(cornerRadius: 2)
                                    .fill(timeRemaining > 5 ? Theme.primaryAccent : Theme.dangerAccent)
                                    .frame(width: barGeo.size.width * (timeRemaining / 15), height: 3)
                            }
                        }
                        .frame(maxWidth: 260, maxHeight: 3)
                        .padding(.top, 6)
                    }
                    .padding(.top, 80)
                    Spacer()
                }

                // Color circles
                ForEach(circles) { circle in
                    if !circle.isHit {
                        Button {
                            handleTap(circle)
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(palette[circle.colorIndex].color.opacity(0.12))
                                    .frame(width: 60, height: 60)

                                Circle()
                                    .fill(palette[circle.colorIndex].color.opacity(0.7))
                                    .frame(width: 40, height: 40)
                                    .shadow(color: palette[circle.colorIndex].color.opacity(0.4), radius: 10)
                            }
                        }
                        .position(circle.position)
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityLabel("\(palette[circle.colorIndex].name) circle")
                    }
                }

                // Wrong flash
                if wrongFlash {
                    Color.red.opacity(0.15)
                        .ignoresSafeArea()
                        .transition(.opacity)
                }

                // Completion overlay
                if completed {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Theme.successAccent)
                        Text("OVERRIDE ACCEPTED")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .tracking(4)
                            .foregroundStyle(Theme.successAccent)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if !hasGenerated {
                        targetColorIndex = Int.random(in: 0..<palette.count)
                        generateCircles(in: geo.size)
                        hasGenerated = true
                    }
                }
            }
            .onReceive(timer) { _ in
                guard !completed else { return }
                timeRemaining -= 0.1
                if timeRemaining <= 0 {
                    // Regenerate on timeout
                    regenerateCircles(in: geo.size)
                }
            }
        }
    }

    private func generateCircles(in size: CGSize) {
        let padding: CGFloat = 40
        let minY = size.height * 0.28
        let maxY = size.height * 0.88
        let minX = padding
        let maxX = size.width - padding

        var newCircles: [ColorCircle] = []

        // Ensure enough target-color circles
        let targetCount = Int.random(in: 5...7)
        let otherCount = Int.random(in: 3...5)

        for _ in 0..<targetCount {
            let pos = randomPoint(in: minX...maxX, yRange: minY...maxY, avoiding: newCircles.map(\.position))
            newCircles.append(ColorCircle(position: pos, colorIndex: targetColorIndex))
        }

        for _ in 0..<otherCount {
            var idx: Int
            repeat {
                idx = Int.random(in: 0..<palette.count)
            } while idx == targetColorIndex
            let pos = randomPoint(in: minX...maxX, yRange: minY...maxY, avoiding: newCircles.map(\.position))
            newCircles.append(ColorCircle(position: pos, colorIndex: idx))
        }

        circles = newCircles.shuffled()
    }

    private func regenerateCircles(in size: CGSize) {
        timeRemaining = 15
        withAnimation(.spring(response: 0.3)) {
            generateCircles(in: size)
        }
    }

    private func randomPoint(in xRange: ClosedRange<CGFloat>, yRange: ClosedRange<CGFloat>, avoiding: [CGPoint]) -> CGPoint {
        var point: CGPoint
        var attempts = 0
        repeat {
            point = CGPoint(
                x: CGFloat.random(in: xRange),
                y: CGFloat.random(in: yRange)
            )
            attempts += 1
        } while avoiding.contains(where: { dist($0, point) < 70 }) && attempts < 80
        return point
    }

    private func handleTap(_ circle: ColorCircle) {
        guard !completed else { return }

        if circle.colorIndex == targetColorIndex {
            HapticsManager.shared.lightTap()
            withAnimation(.spring(response: 0.3)) {
                if let idx = circles.firstIndex(where: { $0.id == circle.id }) {
                    circles[idx].isHit = true
                }
                score += 1
            }

            if score >= requiredScore {
                HapticsManager.shared.success()
                HapticsManager.shared.playSuccessSound()
                timer.upstream.connect().cancel()
                withAnimation(.easeInOut(duration: 0.4).delay(0.2)) {
                    completed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    onComplete()
                }
            }
        } else {
            HapticsManager.shared.error()
            HapticsManager.shared.playErrorSound()
            withAnimation(.easeInOut(duration: 0.15)) { wrongFlash = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeOut(duration: 0.2)) { wrongFlash = false }
            }
        }
    }

    private func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2))
    }
}
