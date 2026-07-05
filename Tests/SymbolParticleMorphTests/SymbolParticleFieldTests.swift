import SwiftUI
import Testing
@testable import SymbolParticleMorph

@Suite
struct SymbolParticleFieldTests {
    @Test
    func morphRetargetingReusesExistingParticlePositions() {
        var particles = [
            particle(x: 1, y: 2, baseX: 1, baseY: 2),
            particle(x: 3, y: 4, baseX: 3, baseY: 4),
        ]
        let targets = [
            particle(x: 10, y: 20, baseX: 10, baseY: 20),
            particle(x: 30, y: 40, baseX: 30, baseY: 40),
            particle(x: 50, y: 60, baseX: 50, baseY: 60),
        ]

        SymbolParticleField.retarget(&particles, to: targets)

        #expect(particles.count == 3)
        #expect(particles[0].x == 1)
        #expect(particles[0].y == 2)
        #expect(particles[0].baseX == 10)
        #expect(particles[0].baseY == 20)
        #expect(particles[1].x == 3)
        #expect(particles[1].y == 4)
        #expect(particles[1].baseX == 30)
        #expect(particles[1].baseY == 40)
        #expect(particles[2].x == 50)
        #expect(particles[2].y == 60)
    }

    private func particle(x: Double, y: Double, baseX: Double, baseY: Double) -> SymbolParticle {
        SymbolParticle(
            x: x,
            y: y,
            baseX: baseX,
            baseY: baseY,
            density: 10,
            z: 0.5,
            color: .accentColor
        )
    }
}
