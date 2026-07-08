import CoreGraphics
import Testing
@testable import SymbolParticleMorph

@Suite
struct ParticleMorphConfigurationTests {
    @Test
    func defaultConfigurationUsesBalancedPreset() {
        let configuration = ParticleMorphConfiguration()

        #expect(configuration.quality == .balanced)
        #expect(configuration.maxParticleCount == 1_100)
        #expect(configuration.samplingStep == 5)
        #expect(configuration.particleSizeRange == 2.2...3.1)
        #expect(configuration.frameBudget == 54)
        #expect(configuration.frameRate == 45)
        #expect(configuration.revealDuration == 0.8)
        #expect(configuration.primaryColor == .systemBlue)
        #expect(configuration.secondaryColor == .secondaryGray)
    }

    @Test(arguments: [
        (ParticleMorphQuality.compact, 320, 8, 1.6...2.3),
        (ParticleMorphQuality.balanced, 1_100, 5, 2.2...3.1),
        (ParticleMorphQuality.detailed, 1_800, 3, 2.8...3.8),
    ])
    func qualityPresetsChooseExpectedDefaults(
        quality: ParticleMorphQuality,
        maxParticleCount: Int,
        samplingStep: Int,
        particleSizeRange: ClosedRange<Double>
    ) {
        let configuration = ParticleMorphConfiguration(quality: quality)

        #expect(configuration.maxParticleCount == maxParticleCount)
        #expect(configuration.samplingStep == samplingStep)
        #expect(configuration.particleSizeRange == particleSizeRange)
    }

    @Test
    func invalidNumericInputsClampToSafeValues() {
        let configuration = ParticleMorphConfiguration(
            maxParticleCount: -20,
            samplingStep: 0,
            contentInset: -8,
            revealDuration: -1,
            frameBudget: -5,
            frameRate: 0,
            symbolPointSize: 0
        )

        #expect(configuration.maxParticleCount == 1)
        #expect(configuration.samplingStep == 1)
        #expect(configuration.contentInset == 0)
        #expect(configuration.revealDuration == 0)
        #expect(configuration.frameBudget == 0)
        #expect(configuration.frameRate == 1)
        #expect(configuration.symbolPointSize == 1)
    }

    @Test
    func symbolColorsClampToValidChannelRange() {
        let color = SymbolParticleColor(red: -1, green: 0.5, blue: 2, opacity: 1.5)

        #expect(color.red == 0)
        #expect(color.green == 0.5)
        #expect(color.blue == 1)
        #expect(color.opacity == 1)
    }
}
