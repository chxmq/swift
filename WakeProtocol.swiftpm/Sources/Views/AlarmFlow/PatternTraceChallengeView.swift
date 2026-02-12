import SwiftUI

/// Pattern trace challenge — trace a path through waypoints to prove alertness
struct PatternTraceChallengeView: View {
    let onComplete: () -> Void

    @State private var waypoints: [CGPoint] = []
    @State private var currentIndex = 0
    @State private var tracePoints: [CGPoint] = []
    @State private var isTracing = false
    @State private var completed = false
    @State private var hasGenerated = false

    private let waypointCount = 5
    private let hitRadius: CGFloat = 35

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

                        Text("TRACE THE PATH THROUGH ALL NODES")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .tracking(2)
                            .foregroundStyle(Theme.textSecondary)

                        // Progress
                        HStack(spacing: 6) {
                            ForEach(0..<waypointCount, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(i < currentIndex ? Theme.successAccent : Theme.textTertiary)
                                    .frame(width: 30, height: 4)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.top, 80)
                    Spacer()
                }

                // Connection lines (target path)
                if waypoints.count > 1 {
                    Path { path in
                        path.move(to: waypoints[0])
                        for i in 1..<waypoints.count {
                            path.addLine(to: waypoints[i])
                        }
                    }
                    .stroke(Theme.primaryAccent.opacity(0.15), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                }

                // User trace line
                if tracePoints.count > 1 {
                    Path { path in
                        path.move(to: tracePoints[0])
                        for i in 1..<tracePoints.count {
                            path.addLine(to: tracePoints[i])
                        }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [Theme.primaryAccent, Theme.successAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )
                }

                // Waypoint nodes
                ForEach(Array(waypoints.enumerated()), id: \.offset) { index, point in
                    ZStack {
                        // Pulse ring for current target
                        if index == currentIndex {
                            Circle()
                                .stroke(Theme.primaryAccent.opacity(0.3), lineWidth: 2)
                                .frame(width: 60, height: 60)
                                .scaleEffect(isTracing ? 1.2 : 1.0)
                                .opacity(isTracing ? 0.5 : 1.0)
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isTracing)
                        }

                        Circle()
                            .fill(
                                index < currentIndex
                                    ? Theme.successAccent.opacity(0.2)
                                    : (index == currentIndex
                                       ? Theme.primaryAccent.opacity(0.15)
                                       : Theme.surface)
                            )
                            .frame(width: 44, height: 44)

                        Circle()
                            .stroke(
                                index < currentIndex ? Theme.successAccent : Theme.primaryAccent,
                                lineWidth: 2
                            )
                            .frame(width: 44, height: 44)

                        if index < currentIndex {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Theme.successAccent)
                        } else {
                            Text("\(index + 1)")
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundStyle(
                                    index == currentIndex ? Theme.primaryAccent : Theme.textSecondary
                                )
                        }
                    }
                    .position(point)
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
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard !completed else { return }
                        if !isTracing {
                            isTracing = true
                        }
                        tracePoints.append(value.location)
                        checkWaypointHit(value.location)
                    }
            )
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if !hasGenerated {
                        generateWaypoints(in: geo.size)
                        hasGenerated = true
                        isTracing = true
                    }
                }
            }
        }
        .accessibilityLabel("Pattern trace challenge. Drag your finger through all numbered nodes in order.")
    }

    private func generateWaypoints(in size: CGSize) {
        let padding: CGFloat = 55
        let minY = size.height * 0.28
        let maxY = size.height * 0.82
        let minX = padding
        let maxX = size.width - padding

        var points: [CGPoint] = []
        for _ in 0..<waypointCount {
            var point: CGPoint
            var attempts = 0
            repeat {
                point = CGPoint(
                    x: CGFloat.random(in: minX...maxX),
                    y: CGFloat.random(in: minY...maxY)
                )
                attempts += 1
            } while points.contains(where: { dist($0, point) < 100 }) && attempts < 100
            points.append(point)
        }
        waypoints = points
    }

    private func checkWaypointHit(_ point: CGPoint) {
        guard currentIndex < waypoints.count else { return }
        let target = waypoints[currentIndex]
        if dist(point, target) < hitRadius {
            HapticsManager.shared.lightTap()
            withAnimation(.spring(response: 0.3)) {
                currentIndex += 1
            }
            if currentIndex >= waypointCount {
                HapticsManager.shared.success()
                HapticsManager.shared.playSuccessSound()
                withAnimation(.easeInOut(duration: 0.4).delay(0.2)) {
                    completed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    onComplete()
                }
            }
        }
    }

    private func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2))
    }
}
