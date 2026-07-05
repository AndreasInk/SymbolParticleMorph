import Combine
import OSLog
import SwiftUI

/// A SwiftUI view that renders an SF Symbol as a field of particles and morphs the field when the symbol changes.
public struct SymbolParticleMorph: View {
    private static let logger = Logger(subsystem: "com.andreasink.SymbolParticleMorph", category: "SymbolParticleMorph")
    private static let signposter = OSSignposter(subsystem: "com.andreasink.SymbolParticleMorph", category: "SymbolParticleMorph")

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let symbolName: String
    private let configuration: ParticleMorphConfiguration
    private let timer: Publishers.Autoconnect<Timer.TimerPublisher>

    @State private var particles: [SymbolParticle] = []
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
            let minParticleSize = min(configuration.particleSizeRange.lowerBound, configuration.particleSizeRange.upperBound)
            let maxParticleSize = max(configuration.particleSizeRange.lowerBound, configuration.particleSizeRange.upperBound)

            for (index, particle) in particles.enumerated() {
                let size = maxParticleSize - (maxParticleSize - minParticleSize) * particle.z
                let rect = CGRect(x: particle.x, y: particle.y, width: size, height: size)
                let opacity = revealOpacity(for: particle, index: index, totalCount: particles.count)
                guard opacity > 0 else { continue }
                context.fill(Path(ellipseIn: rect), with: .color(particle.color.opacity(opacity)))
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
            swirlTime += 0.02
            Self.signposter.endInterval("ParticleFrame", state)
            frameTickCount &+= 1
            logParticleMetricsIfNeeded()
        }
        .onChange(of: symbolName) {
            rebuildParticles(restartReveal: true)
        }
        .onAppear {
            rebuildParticles(restartReveal: true)
        }
        .onDisappear {
            revealTask?.cancel()
        }
    }

    private func updateSize(_ newSize: CGSize) {
        guard newSize != viewSize else { return }
        viewSize = newSize
        rebuildParticles(restartReveal: particles.isEmpty)
    }

    private func updateParticles() {
        for index in particles.indices {
            particles[index].update(swirlTime: swirlTime)
        }
    }

    private func rebuildParticles(restartReveal: Bool) {
        guard viewSize.width > 0, viewSize.height > 0 else { return }
        let hadParticles = !particles.isEmpty
        let targets = SymbolParticleTargetGenerator.targets(
            for: symbolName,
            in: viewSize,
            configuration: configuration
        )
        SymbolParticleField.retarget(&particles, to: targets)
        activeFrames = reduceMotion ? 0 : configuration.frameBudget

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

        let stableSeed = ((particle.baseX * 0.013) + (particle.baseY * 0.021)).truncatingRemainder(dividingBy: 1)
        let normalizedSeed = stableSeed >= 0 ? stableSeed : stableSeed + 1
        let normalizedIndex = totalCount > 1 ? Double(index) / Double(totalCount - 1) : 0
        let revealAnchor = min(1, normalizedSeed * 0.7 + normalizedIndex * 0.3)
        let fadeWindow = 0.22
        return ((revealProgress - revealAnchor) / fadeWindow).clamped(to: 0...1)
    }

    private func logParticleMetricsIfNeeded() {
        let now = Date()
        guard now.timeIntervalSince(lastMetricsLogTime) >= 5 else { return }
        lastMetricsLogTime = now
        Self.logger.debug(
            "ticks=\(self.frameTickCount, privacy: .public) particles=\(self.particles.count, privacy: .public)"
        )
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
