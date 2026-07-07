import CoreGraphics

struct SymbolParticle {
    fileprivate enum Constants {
        static let spring = 0.008
        static let damping = 0.65
        static let swirlBase = 0.0012
        static let swirlAmplitude = 0.0006
        static let retargetImpulse = 0.04
        static let opacityResponse = 0.2
        static let opacitySnapThreshold = 0.01
    }

    var x: Double
    var y: Double
    var baseX: Double
    var baseY: Double
    let density: Double
    var z: Double
    var color: SymbolParticleColor
    var velocityX: Double = 0
    var velocityY: Double = 0
    var opacity: Double = 1
    var targetOpacity: Double = 1

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

        opacity += (targetOpacity - opacity) * Constants.opacityResponse
        if abs(targetOpacity - opacity) < Constants.opacitySnapThreshold {
            opacity = targetOpacity
        }
    }
}

final class SymbolParticleField {
    private(set) var particles: [SymbolParticle] = []
    private var retargetGeneration = 0
    private var hasRetiringParticles = false

    var isEmpty: Bool {
        particles.isEmpty
    }

    var count: Int {
        particles.count
    }

    func update(swirlTime: Double) {
        for index in particles.indices {
            particles[index].update(swirlTime: swirlTime)
        }

        guard hasRetiringParticles else { return }
        particles.removeAll { particle in
            particle.targetOpacity == 0 && particle.opacity <= SymbolParticle.Constants.opacitySnapThreshold
        }
        hasRetiringParticles = particles.contains { $0.targetOpacity == 0 }
    }

    func forEachParticle(_ body: (_ index: Int, _ particle: SymbolParticle, _ totalCount: Int) -> Void) {
        let totalCount = particles.count
        for index in particles.indices {
            body(index, particles[index], totalCount)
        }
    }

    func retarget(to targets: [SymbolParticle], animated: Bool = true) {
        if animated {
            retargetGeneration &+= 1
        }
        Self.retarget(&particles, to: targets, animated: animated, generation: retargetGeneration)
        hasRetiringParticles = particles.contains { $0.targetOpacity == 0 }
    }

    static func retarget(_ particles: inout [SymbolParticle], to targets: [SymbolParticle]) {
        retarget(&particles, to: targets, animated: false, generation: 0)
    }

    private static func retarget(
        _ particles: inout [SymbolParticle],
        to targets: [SymbolParticle],
        animated: Bool,
        generation: Int
    ) {
        if particles.isEmpty {
            particles.removeAll(keepingCapacity: true)
            particles.reserveCapacity(targets.count)
            for target in targets {
                var particle = target
                particle.x = target.baseX
                particle.y = target.baseY
                particle.opacity = 1
                particle.targetOpacity = 1
                particles.append(particle)
            }
            return
        }

        guard animated else {
            retargetDirectly(&particles, to: targets)
            return
        }

        retargetAnimated(&particles, to: targets, generation: generation)
    }

    private static func retargetDirectly(_ particles: inout [SymbolParticle], to targets: [SymbolParticle]) {
        let targetCount = targets.count
        for index in 0..<min(particles.count, targetCount) {
            particles[index].baseX = targets[index].baseX
            particles[index].baseY = targets[index].baseY
            particles[index].z = targets[index].z
            particles[index].color = targets[index].color
            particles[index].targetOpacity = 1
            if particles[index].opacity == 0 {
                particles[index].opacity = 1
            }
        }

        if targetCount > particles.count {
            particles.reserveCapacity(targetCount)
            for index in particles.count..<targetCount {
                var particle = targets[index]
                particle.opacity = 1
                particle.targetOpacity = 1
                particles.append(particle)
            }
        } else if particles.count > targetCount {
            particles.removeLast(particles.count - targetCount)
        }

        for index in particles.indices {
            particles[index].velocityX = (particles[index].baseX - particles[index].x) * SymbolParticle.Constants.retargetImpulse
            particles[index].velocityY = (particles[index].baseY - particles[index].y) * SymbolParticle.Constants.retargetImpulse
        }
    }

    private static func retargetAnimated(
        _ particles: inout [SymbolParticle],
        to targets: [SymbolParticle],
        generation: Int
    ) {
        let originalCount = particles.count
        let targetCount = targets.count
        guard targetCount > 0 else {
            for index in particles.indices {
                particles[index].targetOpacity = 0
            }
            return
        }

        let assignment = TargetAssignment(count: targetCount, generation: generation)
        let reusableCount = min(originalCount, targetCount)
        for slot in 0..<reusableCount {
            particles[slot].applyTarget(targets[assignment.index(for: slot)], targetOpacity: 1)
        }

        if targetCount > originalCount {
            particles.reserveCapacity(targetCount)
            for slot in originalCount..<targetCount {
                let target = targets[assignment.index(for: slot)]
                let seed = particles[seedIndex(for: slot, originalCount: originalCount, targetCount: targetCount)]
                var particle = target
                particle.x = seed.x
                particle.y = seed.y
                particle.velocityX = seed.velocityX
                particle.velocityY = seed.velocityY
                particle.opacity = 0
                particle.targetOpacity = 1
                particles.append(particle)
            }
        } else if originalCount > targetCount {
            for slot in targetCount..<originalCount {
                particles[slot].applyTarget(targets[assignment.index(for: slot)], targetOpacity: 0)
            }
        }

        for index in particles.indices {
            particles[index].velocityX += (particles[index].baseX - particles[index].x) * SymbolParticle.Constants.retargetImpulse
            particles[index].velocityY += (particles[index].baseY - particles[index].y) * SymbolParticle.Constants.retargetImpulse
        }
    }

    private static func seedIndex(for slot: Int, originalCount: Int, targetCount: Int) -> Int {
        min(originalCount - 1, slot * originalCount / max(1, targetCount))
    }
}

private extension SymbolParticle {
    mutating func applyTarget(_ target: SymbolParticle, targetOpacity: Double) {
        baseX = target.baseX
        baseY = target.baseY
        z = target.z
        color = target.color
        self.targetOpacity = targetOpacity
    }
}

private struct TargetAssignment {
    let count: Int
    let stride: Int
    let offset: Int

    init(count: Int, generation: Int) {
        self.count = count
        guard count > 2 else {
            self.stride = 1
            self.offset = count > 0 ? generation % count : 0
            return
        }

        // Avoid row-scan identity matching so visually similar symbols still visibly morph.
        var candidate = max(1, count / 2)
        if candidate.isMultiple(of: 2) {
            candidate += 1
        }
        while greatestCommonDivisor(candidate, count) != 1 {
            candidate += 2
            if candidate >= count {
                candidate = 1
                break
            }
        }

        self.stride = candidate
        self.offset = (generation * max(1, count / 3)) % count
    }

    func index(for slot: Int) -> Int {
        guard count > 0 else { return 0 }
        return (slot &* stride &+ offset) % count
    }
}

private func greatestCommonDivisor(_ lhs: Int, _ rhs: Int) -> Int {
    var a = lhs
    var b = rhs
    while b != 0 {
        let remainder = a % b
        a = b
        b = remainder
    }
    return abs(a)
}
