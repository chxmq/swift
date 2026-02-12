import SwiftUI

/// Dismiss challenge — tap scattered numbers 1-6 in order to prove alertness
struct DismissChallengeView: View {
    let onComplete: () -> Void

    @State private var nodes: [ChallengeNode] = []
    @State private var nextTarget = 1
    @State private var wrongFlash = false
    @State private var completed = false
    @State private var hasGenerated = false

    struct ChallengeNode: Identifiable {
        let id: Int
        var position: CGPoint
        var isFound = false
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Danger background pulse
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

                        Text("TAP NODES 1 → 6 IN SEQUENCE")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .tracking(2)
                            .foregroundStyle(Theme.textSecondary)

                        // Progress bar
                        HStack(spacing: 6) {
                            ForEach(1...6, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(i < nextTarget ? Theme.successAccent : Theme.textTertiary)
                                    .frame(width: 30, height: 4)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.top, 80)
                    Spacer()
                }

                // Challenge nodes
                ForEach(nodes) { node in
                    Button {
                        handleTap(node)
                    } label: {
                        ZStack {
                            // Outer glow
                            Circle()
                                .fill(
                                    node.isFound
                                        ? Theme.successAccent.opacity(0.15)
                                        : Theme.primaryAccent.opacity(0.08)
                                )
                                .frame(width: 70, height: 70)

                            // Border ring
                            Circle()
                                .stroke(
                                    node.isFound ? Theme.successAccent : Theme.primaryAccent,
                                    lineWidth: 2
                                )
                                .frame(width: 56, height: 56)

                            // Number
                            Text("\(node.id)")
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundStyle(
                                    node.isFound ? Theme.successAccent : Theme.primaryAccent
                                )
                        }
                    }
                    .disabled(node.isFound)
                    .position(node.position)
                }

                // Wrong tap flash
                if wrongFlash {
                    Color.red.opacity(0.15)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    Text("WRONG SEQUENCE")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .tracking(4)
                        .foregroundStyle(Theme.dangerAccent)
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
            .onChange(of: geo.size) { _, newSize in
                if !hasGenerated {
                    generateNodes(in: newSize)
                    hasGenerated = true
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if !hasGenerated {
                        generateNodes(in: geo.size)
                        hasGenerated = true
                    }
                }
            }
        }
    }

    // MARK: - Node generation with collision avoidance
    private func generateNodes(in size: CGSize) {
        let padding: CGFloat = 50
        let minY = size.height * 0.25
        let maxY = size.height * 0.85
        let minX = padding
        let maxX = size.width - padding

        var positions: [CGPoint] = []
        for _ in 1...6 {
            var point: CGPoint
            var attempts = 0
            repeat {
                point = CGPoint(
                    x: CGFloat.random(in: minX...maxX),
                    y: CGFloat.random(in: minY...maxY)
                )
                attempts += 1
            } while positions.contains(where: { dist($0, point) < 90 }) && attempts < 100
            positions.append(point)
        }

        nodes = positions.enumerated().map { i, pos in
            ChallengeNode(id: i + 1, position: pos)
        }
    }

    private func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2))
    }

    // MARK: - Tap handling
    private func handleTap(_ node: ChallengeNode) {
        guard !completed else { return }

        if node.id == nextTarget {
            HapticsManager.shared.lightTap()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                if let idx = nodes.firstIndex(where: { $0.id == node.id }) {
                    nodes[idx].isFound = true
                }
                nextTarget += 1
            }

            if nextTarget > 6 {
                HapticsManager.shared.success()
                HapticsManager.shared.playSuccessSound()
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 0.2)) { wrongFlash = false }
            }
        }
    }
}
