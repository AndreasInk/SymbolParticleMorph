#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
import CoreGraphics
import SwiftUI

struct SymbolImageCacheKey: Hashable {
    let symbolName: String
    let width: Int
    let height: Int
    let scale: Double
    let renderingStyle: SymbolParticleRenderingStyle
    let primaryColor: SymbolParticleColor
    let secondaryColor: SymbolParticleColor
    let symbolPointSize: Double
}

@MainActor
final class SymbolImageCache {
    static let shared = SymbolImageCache()
    private static let defaultMaxEntryCount = 128

    private var cache: [SymbolImageCacheKey: CGImage] = [:]
    private var keysByRecentUse: [SymbolImageCacheKey] = []
    private let maxEntryCount: Int

    init(maxEntryCount: Int = SymbolImageCache.defaultMaxEntryCount) {
        self.maxEntryCount = max(1, maxEntryCount)
    }

    var count: Int {
        cache.count
    }

    func image(
        for symbolName: String,
        size: CGSize,
        configuration: ParticleMorphConfiguration
    ) -> CGImage? {
        let scale = displayScale
        let key = SymbolImageCacheKey(
            symbolName: symbolName,
            width: Int(size.width.rounded(.toNearestOrAwayFromZero)),
            height: Int(size.height.rounded(.toNearestOrAwayFromZero)),
            scale: scale,
            renderingStyle: configuration.renderingStyle,
            primaryColor: configuration.primaryColor,
            secondaryColor: configuration.secondaryColor,
            symbolPointSize: Double(configuration.symbolPointSize)
        )

        if let cached = cache[key] {
            markRecentlyUsed(key)
            return cached
        }

        guard let rendered = renderSymbol(symbolName, size: size, scale: scale, configuration: configuration) else {
            return nil
        }
        insert(rendered, for: key)
        return rendered
    }

    func clear() {
        cache.removeAll()
        keysByRecentUse.removeAll()
    }

    private var displayScale: Double {
        #if os(iOS)
        Double(UIScreen.main.scale)
        #else
        Double(NSScreen.main?.backingScaleFactor ?? 2.0)
        #endif
    }

    private func renderSymbol(
        _ symbolName: String,
        size: CGSize,
        scale: Double,
        configuration: ParticleMorphConfiguration
    ) -> CGImage? {
        let renderSize = CGSize(
            width: max(1, size.width),
            height: max(1, size.height)
        )
        let renderer = ImageRenderer(
            content: symbolView(
                symbolName: symbolName,
                size: renderSize,
                configuration: configuration
            )
        )
        renderer.scale = scale

        #if os(iOS)
        return renderer.uiImage?.cgImage
        #else
        guard let nsImage = renderer.nsImage else { return nil }
        return nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
        #endif
    }

    @ViewBuilder
    private func symbolView(
        symbolName: String,
        size: CGSize,
        configuration: ParticleMorphConfiguration
    ) -> some View {
        let paddedSize = CGSize(
            width: max(size.width, configuration.symbolPointSize * Constants.symbolPaddingMultiplier),
            height: max(size.height, configuration.symbolPointSize * Constants.symbolPaddingMultiplier)
        )
        let base = Image(systemName: symbolName)
            .font(.system(size: configuration.symbolPointSize, weight: .regular, design: .default))
            .brightness(Constants.symbolBrightnessBoost)
        let primaryColor = Color(configuration.primaryColor)
        let secondaryColor = Color(configuration.secondaryColor)

        switch configuration.renderingStyle {
        case .hierarchical:
            base
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(primaryColor)
                .frame(width: paddedSize.width, height: paddedSize.height)
                .drawingGroup()
        case .monochrome:
            base
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(primaryColor)
                .frame(width: paddedSize.width, height: paddedSize.height)
                .drawingGroup()
        case .palette:
            base
                .symbolRenderingMode(.palette)
                .foregroundStyle(primaryColor, secondaryColor)
                .frame(width: paddedSize.width, height: paddedSize.height)
                .drawingGroup()
        }
    }

    private func insert(_ image: CGImage, for key: SymbolImageCacheKey) {
        cache[key] = image
        markRecentlyUsed(key)

        while cache.count > maxEntryCount, let leastRecentKey = keysByRecentUse.first {
            cache.removeValue(forKey: leastRecentKey)
            keysByRecentUse.removeFirst()
        }
    }

    private func markRecentlyUsed(_ key: SymbolImageCacheKey) {
        keysByRecentUse.removeAll { $0 == key }
        keysByRecentUse.append(key)
    }

    private enum Constants {
        static let symbolPaddingMultiplier = 1.35
        static let symbolBrightnessBoost = 0.2
    }
}

private extension Color {
    init(_ color: SymbolParticleColor) {
        self.init(
            red: color.red,
            green: color.green,
            blue: color.blue,
            opacity: color.opacity
        )
    }
}

/// Utilities for warming or clearing the shared symbol image cache used by `SymbolParticleMorph`.
public enum SymbolParticleMorphCache {
    /// Pre-rasterizes symbols into the shared cache.
    ///
    /// Call this from the main actor before a high-traffic screen appears when you know the symbols that will
    /// be used. The package does not perform any network or analytics work.
    @MainActor
    public static func preload(
        symbols: [String],
        size: CGSize = CGSize(width: 80, height: 80),
        configuration: ParticleMorphConfiguration = ParticleMorphConfiguration()
    ) {
        for symbol in symbols {
            _ = SymbolImageCache.shared.image(for: symbol, size: size, configuration: configuration)
        }
    }

    /// Clears all rasterized symbols from the shared cache.
    @MainActor
    public static func clear() {
        SymbolImageCache.shared.clear()
    }
}
