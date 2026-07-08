import CoreGraphics
import Testing
@testable import SymbolParticleMorph

@Suite
struct SymbolParticleTargetGeneratorTests {
    @Test
    func particleCapIsHonored() {
        let image = filledImage(width: 10, height: 10)
        let configuration = ParticleMorphConfiguration(
            maxParticleCount: 12,
            samplingStep: 1
        )

        let targets = SymbolParticleTargetGenerator.targets(
            from: image,
            in: CGSize(width: 100, height: 100),
            configuration: configuration
        )

        #expect(targets.count <= 12)
        #expect(targets.count > 0)
    }

    @Test
    func particleCapStopsAtMaximumForNonDivisibleSourceCounts() {
        let image = filledImage(width: 11, height: 11)
        let configuration = ParticleMorphConfiguration(
            maxParticleCount: 50,
            samplingStep: 1
        )

        let targets = SymbolParticleTargetGenerator.targets(
            from: image,
            in: CGSize(width: 100, height: 100),
            configuration: configuration
        )

        #expect(targets.count == 50)
    }

    @Test
    func contentInsetKeepsParticlesInsideDrawableBounds() {
        let image = filledImage(width: 4, height: 4)
        let configuration = ParticleMorphConfiguration(
            maxParticleCount: 100,
            samplingStep: 1,
            contentInset: 10
        )

        let targets = SymbolParticleTargetGenerator.targets(
            from: image,
            in: CGSize(width: 80, height: 60),
            configuration: configuration
        )

        #expect(!targets.isEmpty)
        for target in targets {
            #expect(target.baseX >= 10)
            #expect(target.baseX <= 70)
            #expect(target.baseY >= 10)
            #expect(target.baseY <= 50)
        }
    }

    @Test
    func transparentPixelsAreIgnored() {
        let image = SymbolPixelImage(
            width: 2,
            height: 1,
            data: [
                255, 255, 255, 255,
                255, 255, 255, 0,
            ]
        )
        let configuration = ParticleMorphConfiguration(
            maxParticleCount: 10,
            samplingStep: 1
        )

        let targets = SymbolParticleTargetGenerator.targets(
            from: image,
            in: CGSize(width: 20, height: 20),
            configuration: configuration
        )

        #expect(targets.count == 1)
    }

    @Test
    func alphaThresholdRequiresVisiblePixelsAboveCutoff() {
        let image = SymbolPixelImage(
            width: 2,
            height: 1,
            data: [
                255, 255, 255, 50,
                255, 255, 255, 51,
            ]
        )
        let configuration = ParticleMorphConfiguration(
            maxParticleCount: 10,
            samplingStep: 1
        )

        let targets = SymbolParticleTargetGenerator.targets(
            from: image,
            in: CGSize(width: 20, height: 20),
            configuration: configuration
        )

        #expect(targets.count == 1)
    }

    @Test
    func invalidRowStrideProducesNoTargets() {
        let image = filledImage(width: 2, height: 2)
        let configuration = ParticleMorphConfiguration(
            maxParticleCount: 10,
            samplingStep: 1
        )

        let targets = SymbolParticleTargetGenerator.targets(
            from: image,
            in: CGSize(width: 20, height: 20),
            configuration: configuration,
            bytesPerRow: 4
        )

        #expect(targets.isEmpty)
    }

    @Test
    func emptyPixelDataProducesNoTargets() {
        let image = SymbolPixelImage(width: 2, height: 2, data: [])
        let configuration = ParticleMorphConfiguration(
            maxParticleCount: 10,
            samplingStep: 1
        )

        let targets = SymbolParticleTargetGenerator.targets(
            from: image,
            in: CGSize(width: 20, height: 20),
            configuration: configuration
        )

        #expect(targets.isEmpty)
    }

    @Test
    func paddedRowsUseProvidedBytesPerRow() {
        let image = SymbolPixelImage(
            width: 2,
            height: 2,
            data: [
                255, 255, 255, 255, 0, 0, 0, 0, 99, 99, 99, 99,
                0, 0, 0, 0, 255, 255, 255, 255, 88, 88, 88, 88,
            ]
        )
        let configuration = ParticleMorphConfiguration(
            maxParticleCount: 10,
            samplingStep: 1
        )

        let targets = SymbolParticleTargetGenerator.targets(
            from: image,
            in: CGSize(width: 20, height: 20),
            configuration: configuration,
            bytesPerRow: 12
        )

        #expect(targets.count == 2)
    }

    private func filledImage(width: Int, height: Int) -> SymbolPixelImage {
        let pixel = [UInt8](arrayLiteral: 255, 255, 255, 255)
        return SymbolPixelImage(width: width, height: height, data: Array(repeating: pixel, count: width * height).flatMap { $0 })
    }
}
