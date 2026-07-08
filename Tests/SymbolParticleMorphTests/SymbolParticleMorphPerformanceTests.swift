import CoreGraphics
import SwiftUI
import XCTest
@testable import SymbolParticleMorph

final class SymbolParticleMorphPerformanceTests: XCTestCase {
    func testDetailedTargetGenerationPerformance() {
        let image = filledImage(width: 160, height: 160)
        let configuration = ParticleMorphConfiguration(
            quality: .detailed,
            maxParticleCount: 1_800,
            samplingStep: 3
        )
        let size = CGSize(width: 220, height: 220)

        measure(metrics: [XCTClockMetric()]) {
            _ = SymbolParticleTargetGenerator.targets(
                from: image,
                in: size,
                configuration: configuration
            )
        }
    }

    @MainActor
    func testCacheHitPerformance() {
        let cache = SymbolImageCache(maxEntryCount: 8)
        let configuration = ParticleMorphConfiguration(quality: .compact)
        let size = CGSize(width: 64, height: 64)

        _ = cache.image(
            for: "hand.thumbsup",
            size: size,
            configuration: configuration
        )

        measure(metrics: [XCTClockMetric()]) {
            for _ in 0..<10_000 {
                _ = cache.image(
                    for: "hand.thumbsup",
                    size: size,
                    configuration: configuration
                )
            }
        }
    }

    func testParticleRetargetAndUpdatePerformance() {
        let sourceTargets = particles(count: 1_800, offset: 0)
        let destinationTargets = particles(count: 1_800, offset: 40)

        measure(metrics: [XCTClockMetric()]) {
            let field = SymbolParticleField()
            field.retarget(to: sourceTargets, animated: false)
            field.retarget(to: destinationTargets)
            for _ in 0..<54 {
                field.update(swirlTime: 0.4)
            }
        }
    }

    private func filledImage(width: Int, height: Int) -> SymbolPixelImage {
        let pixel = [UInt8](arrayLiteral: 255, 255, 255, 255)
        return SymbolPixelImage(
            width: width,
            height: height,
            data: Array(repeating: pixel, count: width * height).flatMap { $0 }
        )
    }

    private func particles(count: Int, offset: Double) -> [SymbolParticle] {
        (0..<count).map { index in
            let x = Double(index % 60) + offset
            let y = Double(index / 60) + offset
            return SymbolParticle(
                x: x,
                y: y,
                baseX: x,
                baseY: y,
                density: 10,
                z: 0.5,
                color: .systemBlue
            )
        }
    }
}
