import CoreGraphics
import Foundation

/// Configuration for a `SymbolParticleMorph` view.
public struct ParticleMorphConfiguration: Equatable, Sendable {
    /// The preset used to fill in omitted quality-dependent values.
    public let quality: ParticleMorphQuality

    /// The maximum number of particles generated from the rasterized symbol.
    public let maxParticleCount: Int

    /// The pixel stride used when sampling the rasterized symbol. Lower values create more particles.
    public let samplingStep: Int

    /// The inset, in points, applied before mapping sampled pixels into the view's frame.
    public let contentInset: CGFloat

    /// The visible point-size range used when drawing particles. Brighter pixels draw closer to the upper bound.
    public let particleSizeRange: ClosedRange<Double>

    /// The duration, in seconds, of the initial particle reveal.
    public let revealDuration: TimeInterval

    /// The number of timer ticks to animate after the symbol appears or changes.
    public let frameBudget: Int

    /// The requested animation frame rate.
    public let frameRate: Double

    /// The SF Symbol rendering style used before particle sampling.
    public let renderingStyle: SymbolParticleRenderingStyle

    /// The primary symbol color used while rasterizing particles.
    public let primaryColor: SymbolParticleColor

    /// The secondary symbol color used for palette rendering.
    public let secondaryColor: SymbolParticleColor

    /// The point size used when rasterizing the SF Symbol before particle sampling.
    public let symbolPointSize: CGFloat

    /// Creates a particle morph configuration.
    ///
    /// Pass `nil` for quality-dependent values to use the chosen preset. Numeric values are clamped to safe
    /// ranges so invalid inputs do not produce empty timers or impossible sampling strides.
    public init(
        quality: ParticleMorphQuality = .balanced,
        maxParticleCount: Int? = nil,
        samplingStep: Int? = nil,
        contentInset: CGFloat = 0,
        particleSizeRange: ClosedRange<Double>? = nil,
        revealDuration: TimeInterval = 0.8,
        frameBudget: Int = 54,
        frameRate: Double = 45,
        renderingStyle: SymbolParticleRenderingStyle = .hierarchical,
        primaryColor: SymbolParticleColor = .systemBlue,
        secondaryColor: SymbolParticleColor = .secondaryGray,
        symbolPointSize: CGFloat = 80
    ) {
        self.quality = quality
        self.maxParticleCount = max(1, maxParticleCount ?? quality.defaultMaxParticleCount)
        self.samplingStep = max(1, samplingStep ?? quality.defaultSamplingStep)
        self.contentInset = max(0, contentInset)
        self.particleSizeRange = particleSizeRange ?? quality.defaultParticleSizeRange
        self.revealDuration = max(0, revealDuration)
        self.frameBudget = max(0, frameBudget)
        self.frameRate = max(1, frameRate)
        self.renderingStyle = renderingStyle
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.symbolPointSize = max(1, symbolPointSize)
    }
}
