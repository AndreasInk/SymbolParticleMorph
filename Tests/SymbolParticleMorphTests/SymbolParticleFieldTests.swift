import SwiftUI
import Testing
@testable import SymbolParticleMorph

@Suite
struct SymbolParticleFieldTests {
    @Test
    func directRetargetingSnapsExistingParticlesToTargets() {
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
        #expect(particles[0].x == 10)
        #expect(particles[0].y == 20)
        #expect(particles[0].baseX == 10)
        #expect(particles[0].baseY == 20)
        #expect(particles[1].x == 30)
        #expect(particles[1].y == 40)
        #expect(particles[1].baseX == 30)
        #expect(particles[1].baseY == 40)
        #expect(particles[2].x == 50)
        #expect(particles[2].y == 60)
    }

    @Test
    func retargetingToFewerParticlesShrinksField() {
        var particles = [
            particle(x: 1, y: 2, baseX: 1, baseY: 2),
            particle(x: 3, y: 4, baseX: 3, baseY: 4),
            particle(x: 5, y: 6, baseX: 5, baseY: 6),
        ]
        let targets = [
            particle(x: 10, y: 20, baseX: 10, baseY: 20),
        ]

        SymbolParticleField.retarget(&particles, to: targets)

        #expect(particles.count == 1)
        #expect(particles[0].x == 10)
        #expect(particles[0].y == 20)
        #expect(particles[0].baseX == 10)
        #expect(particles[0].baseY == 20)
    }

    @Test
    func retargetingToEmptyTargetsClearsField() {
        var particles = [
            particle(x: 1, y: 2, baseX: 1, baseY: 2),
            particle(x: 3, y: 4, baseX: 3, baseY: 4),
        ]

        SymbolParticleField.retarget(&particles, to: [])

        #expect(particles.isEmpty)
    }

    @Test
    func fieldInstanceRetargetsAndUpdatesStoredParticles() {
        let field = SymbolParticleField()
        field.retarget(to: [
            particle(x: 10, y: 20, baseX: 10, baseY: 20),
            particle(x: 30, y: 40, baseX: 30, baseY: 40),
        ], animated: false)

        #expect(field.count == 2)
        #expect(field.particles[0].x == 10)

        field.retarget(to: [
            particle(x: 100, y: 120, baseX: 100, baseY: 120),
        ], animated: false)
        field.update(swirlTime: 0.4)

        #expect(field.count == 1)
        #expect(field.particles[0].baseX == 100)
        #expect(field.particles[0].x == 100)
        #expect(field.particles[0].y == 120)
    }

    @Test
    func nonAnimatedRetargetClearsMotionState() {
        let field = SymbolParticleField()
        field.retarget(to: [
            particle(x: 10, y: 20, baseX: 10, baseY: 20),
            particle(x: 30, y: 40, baseX: 30, baseY: 40),
        ], animated: false)
        field.retarget(to: [
            particle(x: 100, y: 120, baseX: 100, baseY: 120),
            particle(x: 130, y: 140, baseX: 130, baseY: 140),
        ])
        field.update(swirlTime: 0.4)

        field.retarget(to: [
            particle(x: 200, y: 220, baseX: 200, baseY: 220),
            particle(x: 230, y: 240, baseX: 230, baseY: 240),
        ], animated: false)

        #expect(field.particles[0].x == 200)
        #expect(field.particles[0].y == 220)
        #expect(field.particles[0].baseX == 200)
        #expect(field.particles[0].baseY == 220)
        #expect(field.particles[0].velocityX == 0)
        #expect(field.particles[0].velocityY == 0)
        #expect(field.particles[0].opacity == 1)
        #expect(field.particles[0].targetOpacity == 1)
    }

    @Test
    func animatedRetargetToMoreParticlesSeedsNewParticlesFromExistingPositions() {
        let field = SymbolParticleField()
        field.retarget(to: [
            particle(x: 10, y: 20, baseX: 10, baseY: 20),
            particle(x: 30, y: 40, baseX: 30, baseY: 40),
        ], animated: false)

        field.retarget(to: [
            particle(x: 100, y: 120, baseX: 100, baseY: 120),
            particle(x: 130, y: 140, baseX: 130, baseY: 140),
            particle(x: 160, y: 180, baseX: 160, baseY: 180),
            particle(x: 190, y: 200, baseX: 190, baseY: 200),
        ])

        #expect(field.count == 4)
        #expect(field.particles[2].opacity == 0)
        #expect(field.particles[2].targetOpacity == 1)
        #expect(field.particles[2].x != field.particles[2].baseX)
        #expect(field.particles[3].y != field.particles[3].baseY)
    }

    @Test
    func animatedRetargetToFewerParticlesFadesExcessParticlesBeforeRemoving() {
        let field = SymbolParticleField()
        field.retarget(to: [
            particle(x: 10, y: 20, baseX: 10, baseY: 20),
            particle(x: 30, y: 40, baseX: 30, baseY: 40),
            particle(x: 50, y: 60, baseX: 50, baseY: 60),
        ], animated: false)

        field.retarget(to: [
            particle(x: 100, y: 120, baseX: 100, baseY: 120),
        ])

        #expect(field.count == 3)
        #expect(field.particles[1].targetOpacity == 0)
        #expect(field.particles[2].targetOpacity == 0)

        for _ in 0..<32 {
            field.update(swirlTime: 0.4)
        }

        #expect(field.count == 1)
    }

    @Test
    func animatedRetargetPermutesEqualSizedTargets() {
        let field = SymbolParticleField()
        field.retarget(to: [
            particle(x: 1, y: 1, baseX: 1, baseY: 1),
            particle(x: 2, y: 2, baseX: 2, baseY: 2),
            particle(x: 3, y: 3, baseX: 3, baseY: 3),
            particle(x: 4, y: 4, baseX: 4, baseY: 4),
        ], animated: false)

        field.retarget(to: [
            particle(x: 10, y: 10, baseX: 10, baseY: 10),
            particle(x: 20, y: 20, baseX: 20, baseY: 20),
            particle(x: 30, y: 30, baseX: 30, baseY: 30),
            particle(x: 40, y: 40, baseX: 40, baseY: 40),
        ])

        let assignedBaseX = field.particles.map(\.baseX)
        #expect(assignedBaseX != [10, 20, 30, 40])
        #expect(assignedBaseX.sorted() == [10, 20, 30, 40])
    }

    @Test
    func completedRevealKeepsEveryParticleFullyVisible() {
        let field = SymbolParticleField()
        field.retarget(to: [
            particle(x: 10, y: 20, baseX: 10, baseY: 20),
            particle(x: 30, y: 40, baseX: 30, baseY: 40),
            particle(x: 50, y: 60, baseX: 50, baseY: 60),
            particle(x: 70, y: 80, baseX: 70, baseY: 80),
        ], animated: false)
        var frame = ParticleRenderFrame.empty
        frame.replaceItems(with: field.particles)

        let finalRevealOpacities = frame.items.map {
            $0.revealOpacity(progress: 1, fadeWindow: 0.22)
        }

        #expect(finalRevealOpacities.allSatisfy { $0 == 1 })
    }

    @Test
    func retargetingPrecomputesRevealAnchors() {
        let field = SymbolParticleField()
        field.retarget(to: [
            particle(x: 10, y: 20, baseX: 10, baseY: 20),
            particle(x: 30, y: 40, baseX: 30, baseY: 40),
            particle(x: 50, y: 60, baseX: 50, baseY: 60),
        ], animated: false)

        let anchors = field.particles.map(\.revealAnchor)

        #expect(anchors.count == 3)
        #expect(anchors.allSatisfy { (0...1).contains($0) })
        #expect(Set(anchors).count > 1)
    }

    @Test
    func renderFrameSnapshotsParticleState() {
        let field = SymbolParticleField()
        field.retarget(to: [
            particle(x: 10, y: 20, baseX: 10, baseY: 20),
            particle(x: 30, y: 40, baseX: 30, baseY: 40),
        ], animated: false)
        var frame = ParticleRenderFrame.empty
        frame.replaceItems(with: field.particles)

        field.retarget(to: [
            particle(x: 100, y: 120, baseX: 100, baseY: 120),
            particle(x: 130, y: 140, baseX: 130, baseY: 140),
        ], animated: false)
        field.update(swirlTime: 0.2)

        #expect(frame.items.count == 2)
        #expect(frame.items[0].x == 10)
        #expect(frame.items[0].y == 20)
        #expect(frame.items[0].color == .systemBlue)
    }

    private func particle(x: Double, y: Double, baseX: Double, baseY: Double) -> SymbolParticle {
        SymbolParticle(
            x: x,
            y: y,
            baseX: baseX,
            baseY: baseY,
            density: 10,
            z: 0.5,
            color: .systemBlue
        )
    }
}
