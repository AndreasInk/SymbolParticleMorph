import CoreGraphics
import SwiftUI

struct SymbolParticle {
    fileprivate enum Constants {
        static let spring = 0.008
        static let damping = 0.65
        static let swirlBase = 0.0012
        static let swirlAmplitude = 0.0006
        static let retargetImpulse = 0.04
    }

    var x: Double
    var y: Double
    var baseX: Double
    var baseY: Double
    let density: Double
    var z: Double
    var color: Color
    var velocityX: Double = 0
    var velocityY: Double = 0

    mutating func update(swirlTime: Double) {
        let dx = baseX - x
        let dy = baseY - y
        let ax = dx * Constants.spring * density
        let ay = dy * Constants.spring * density

        velocityX = (velocityX + ax) * Constants.damping
        velocityY = (velocityY + ay) * Constants.damping

        x += velocityX
        y += velocityY

        let swirl = Constants.swirlBase + Constants.swirlAmplitude * sin(swirlTime)
        velocityX += -dy * swirl
        velocityY += dx * swirl
    }
}

struct SymbolParticleField {
    static func retarget(_ particles: inout [SymbolParticle], to targets: [SymbolParticle]) {
        if particles.isEmpty {
            particles = targets.map { target in
                var particle = target
                particle.x = target.baseX
                particle.y = target.baseY
                return particle
            }
            return
        }

        let targetCount = targets.count
        for index in 0..<min(particles.count, targetCount) {
            particles[index].baseX = targets[index].baseX
            particles[index].baseY = targets[index].baseY
            particles[index].z = targets[index].z
            particles[index].color = targets[index].color
        }

        if targetCount > particles.count {
            for index in particles.count..<targetCount {
                particles.append(targets[index])
            }
        } else if particles.count > targetCount {
            particles.removeLast(particles.count - targetCount)
        }

        for index in particles.indices {
            particles[index].velocityX = (particles[index].baseX - particles[index].x) * SymbolParticle.Constants.retargetImpulse
            particles[index].velocityY = (particles[index].baseY - particles[index].y) * SymbolParticle.Constants.retargetImpulse
        }
    }
}
