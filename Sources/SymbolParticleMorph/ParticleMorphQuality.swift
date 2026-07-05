import Foundation

/// A coarse quality preset for common symbol particle sizes.
public enum ParticleMorphQuality: String, CaseIterable, Sendable {
    /// A low particle count suitable for 44-72 point status glyphs.
    case compact

    /// A balanced preset suitable for onboarding or medium-size symbol art.
    case balanced

    /// A denser preset suitable for large hero glyphs.
    case detailed

    var defaultMaxParticleCount: Int {
        switch self {
        case .compact: 320
        case .balanced: 1_100
        case .detailed: 1_800
        }
    }

    var defaultSamplingStep: Int {
        switch self {
        case .compact: 8
        case .balanced: 5
        case .detailed: 3
        }
    }

    var defaultParticleSizeRange: ClosedRange<Double> {
        switch self {
        case .compact: 1.6...2.3
        case .balanced: 2.2...3.1
        case .detailed: 2.8...3.8
        }
    }
}
