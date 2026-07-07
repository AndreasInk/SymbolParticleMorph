import Foundation

/// A fixed sRGB color used while rasterizing SF Symbols into particles.
public struct SymbolParticleColor: Equatable, Hashable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let opacity: Double

    public init(red: Double, green: Double, blue: Double, opacity: Double = 1) {
        self.red = red.clampedToColorChannel
        self.green = green.clampedToColorChannel
        self.blue = blue.clampedToColorChannel
        self.opacity = opacity.clampedToColorChannel
    }

    public static let systemBlue = SymbolParticleColor(red: 0, green: 0.478, blue: 1)
    public static let secondaryGray = SymbolParticleColor(red: 0.56, green: 0.56, blue: 0.58)
}

private extension Double {
    var clampedToColorChannel: Double {
        min(max(self, 0), 1)
    }
}
