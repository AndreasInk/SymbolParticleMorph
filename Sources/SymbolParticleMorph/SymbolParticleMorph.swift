import Combine
import OSLog
import SwiftUI

/// A SwiftUI view that renders an SF Symbol as a field of particles and morphs the field when the symbol changes.
public struct SymbolParticleMorph: View {
    private static let logger = Logger(subsystem: "com.andreasink.SymbolParticleMorph", category: "SymbolParticleMorph")
    private static let signposter = OSSignposter(subsystem: "com.andreasink.SymbolParticleMorph", category: "SymbolParticleMorph")
    private enum Constants {
        static let swirlTimeStep = 0.02
        static let metricsLogInterval: TimeInterval = 5
        static let seedXWeight = 0.013
        static let seedYWeight = 0.021
        static let revealSeedWeight = 0.7
        static let revealIndexWeight = 0.3
        static let revealFadeWindow = 0.22
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let symbolName: String
    private let configuration: ParticleMorphConfiguration
    private let timer: Publishers.Autoconnect<Timer.TimerPublisher>

    @State private var particleField = SymbolParticleField()
    @State private var swirlTime: Double = 0
    @State private var viewSize: CGSize = .zero
    @State private var activeFrames: Int = 0
    @State private var frameTickCount: UInt64 = 0
    @State private var lastMetricsLogTime: Date = .distantPast
    @State private var revealProgress: Double = 1
    @State private var revealTask: Task<Void, Never>?

    /// Creates a symbol particle morph view.
    ///
    /// - Parameters:
    ///   - symbolName: The SF Symbol name to rasterize and draw as particles.
    ///   - configuration: Particle density, animation, rendering, and sizing options.
    public init(
        symbolName: String,
        configuration: ParticleMorphConfiguration = ParticleMorphConfiguration()
    ) {
        self.symbolName = symbolName
        self.configuration = configuration
        self.timer = Timer.publish(every: 1 / configuration.frameRate, on: .main, in: .common).autoconnect()
    }

    public var body: some View {
        Canvas(opaque: false, colorMode: .linear, rendersAsynchronously: true) { context, _ in
            _ = frameTickCount
            let minParticleSize = min(configuration.particleSizeRange.lowerBound, configuration.particleSizeRange.upperBound)
            let maxParticleSize = max(configuration.particleSizeRange.lowerBound, configuration.particleSizeRange.upperBound)

            particleField.forEachParticle { index, particle, totalCount in
                let size = maxParticleSize - (maxParticleSize - minParticleSize) * particle.z
                let rect = CGRect(x: particle.x, y: particle.y, width: size, height: size)
                let opacity = particle.opacity * revealOpacity(for: particle, index: index, totalCount: totalCount)
                if opacity > 0 {
                    context.fill(Path(ellipseIn: rect), with: .color(Color(particle.color, opacityMultiplier: opacity)))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { updateSize(proxy.size) }
                    .onChange(of: proxy.size) { _, newSize in updateSize(newSize) }
            }
        )
        .onReceive(timer) { _ in
            guard !reduceMotion else { return }
            guard activeFrames > 0 else { return }
            let state = Self.signposter.beginInterval("ParticleFrame")
            updateParticles()
            activeFrames -= 1
            swirlTime += Constants.swirlTimeStep
            Self.signposter.endInterval("ParticleFrame", state)
            frameTickCount &+= 1
            logParticleMetricsIfNeeded()
        }
        .onChange(of: symbolName) {
            rebuildParticles(restartReveal: false, animateMorph: true)
        }
        .onChange(of: configuration) {
            rebuildParticles(restartReveal: false, animateMorph: false)
        }
        .onAppear {
            rebuildParticles(restartReveal: true, animateMorph: false)
        }
        .onDisappear {
            revealTask?.cancel()
        }
    }

    private func updateSize(_ newSize: CGSize) {
        guard newSize != viewSize else { return }
        viewSize = newSize
        rebuildParticles(restartReveal: particleField.isEmpty, animateMorph: false)
    }

    private func updateParticles() {
        particleField.update(swirlTime: swirlTime)
    }

    private func rebuildParticles(restartReveal: Bool, animateMorph: Bool) {
        guard viewSize.width > 0, viewSize.height > 0 else { return }
        let hadParticles = !particleField.isEmpty
        let targets = SymbolParticleTargetGenerator.targets(
            for: symbolName,
            in: viewSize,
            configuration: configuration
        )
        let shouldAnimateMorph = animateMorph && hadParticles && !reduceMotion && configuration.frameBudget > 0
        particleField.retarget(to: targets, animated: shouldAnimateMorph)
        activeFrames = shouldAnimateMorph ? configuration.frameBudget : 0
        frameTickCount &+= 1

        if restartReveal && hadParticles {
            restartRevealAnimation()
        } else {
            revealProgress = 1
        }
    }

    private func restartRevealAnimation() {
        revealTask?.cancel()

        guard !reduceMotion else {
            revealProgress = 1
            return
        }

        revealProgress = 0
        revealTask = Task { @MainActor in
            await Task.yield()
            withAnimation(.easeOut(duration: configuration.revealDuration)) {
                revealProgress = 1
            }
        }
    }

    private func revealOpacity(for particle: SymbolParticle, index: Int, totalCount: Int) -> Double {
        guard !reduceMotion else { return 1 }

        let stableSeed = (
            (particle.baseX * Constants.seedXWeight)
            + (particle.baseY * Constants.seedYWeight)
        ).truncatingRemainder(dividingBy: 1)
        let normalizedSeed = stableSeed >= 0 ? stableSeed : stableSeed + 1
        let normalizedIndex = totalCount > 1 ? Double(index) / Double(totalCount - 1) : 0
        let revealAnchor = min(
            1,
            normalizedSeed * Constants.revealSeedWeight
                + normalizedIndex * Constants.revealIndexWeight
        )
        return ((revealProgress - revealAnchor) / Constants.revealFadeWindow).clamped(to: 0...1)
    }

    private func logParticleMetricsIfNeeded() {
        let now = Date()
        guard now.timeIntervalSince(lastMetricsLogTime) >= Constants.metricsLogInterval else { return }
        lastMetricsLogTime = now
        Self.logger.debug(
            "ticks=\(self.frameTickCount, privacy: .public) particles=\(self.particleField.count, privacy: .public)"
        )
    }
}

private extension Color {
    init(_ color: SymbolParticleColor, opacityMultiplier: Double = 1) {
        self.init(
            red: color.red,
            green: color.green,
            blue: color.blue,
            opacity: color.opacity * opacityMultiplier
        )
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
