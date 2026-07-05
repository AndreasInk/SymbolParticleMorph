import Foundation

/// The symbol rendering mode used when rasterizing the SF Symbol before sampling particles.
public enum SymbolParticleRenderingStyle: String, CaseIterable, Sendable {
    /// Uses SF Symbols hierarchical rendering with the environment accent color.
    case hierarchical

    /// Uses a single accent-color layer.
    case monochrome

    /// Uses palette rendering with accent and secondary layers.
    case palette
}
