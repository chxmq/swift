import SwiftUI

/// Floating particle system for alarm visual effects
struct ParticleView: View {
    let color: Color
    let intensity: Double // 0-1

    @State private var particles: [Particle] = []
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
        var speed: CGFloat
        var drift: CGFloat
    }

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                for particle in particles {
                    let rect = CGRect(
                        x: particle.x - particle.size / 2,
                        y: particle.y - particle.size / 2,
                        width: particle.size,
                        height: particle.size
                    )
                    context.opacity = particle.opacity
                    context.fill(Circle().path(in: rect), with: .color(color))
                }
            }
            .onReceive(timer) { _ in
                updateParticles(in: geo.size)
            }
            .onAppear {
                initializeParticles(in: geo.size)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func initializeParticles(in size: CGSize) {
        let count = Int(15 * intensity) + 5
        particles = (0..<count).map { _ in
            Particle(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                size: CGFloat.random(in: 2...5),
                opacity: Double.random(in: 0.1...0.5),
                speed: CGFloat.random(in: 0.3...1.5),
                drift: CGFloat.random(in: -0.5...0.5)
            )
        }
    }

    private func updateParticles(in size: CGSize) {
        for i in particles.indices {
            particles[i].y -= particles[i].speed
            particles[i].x += particles[i].drift
            particles[i].opacity *= 0.997

            // Reset when off screen
            if particles[i].y < -10 || particles[i].opacity < 0.05 {
                particles[i].y = size.height + 10
                particles[i].x = CGFloat.random(in: 0...size.width)
                particles[i].opacity = Double.random(in: 0.2...0.6) * intensity
                particles[i].speed = CGFloat.random(in: 0.3...1.5)
            }
        }
    }
}

