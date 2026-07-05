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
    let symbolPointSize: Double
}

@MainActor
final class SymbolImageCache {
    static let shared = SymbolImageCache()

    private var cache: [SymbolImageCacheKey: CGImage] = [:]

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
            symbolPointSize: Double(configuration.symbolPointSize)
        )

        if let cached = cache[key] {
            return cached
        }

        guard let rendered = renderSymbol(symbolName, size: size, scale: scale, configuration: configuration) else {
            return nil
        }
        cache[key] = rendered
        return rendered
    }

    func clear() {
        cache.removeAll()
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

    private func symbolView(
        symbolName: String,
        size: CGSize,
        configuration: ParticleMorphConfiguration
    ) -> AnyView {
        let paddedSize = CGSize(
            width: max(size.width, configuration.symbolPointSize * 1.35),
            height: max(size.height, configuration.symbolPointSize * 1.35)
        )
        let base = Image(systemName: symbolName)
            .font(.system(size: configuration.symbolPointSize, weight: .regular, design: .default))
            .brightness(0.2)

        let styled: AnyView
        switch configuration.renderingStyle {
        case .hierarchical:
            styled = AnyView(
                base
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.accentColor)
            )
        case .monochrome:
            styled = AnyView(
                base
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(Color.accentColor)
            )
        case .palette:
            styled = AnyView(
                base
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.accentColor, .secondary)
            )
        }

        return AnyView(
            styled
                .frame(width: paddedSize.width, height: paddedSize.height)
                .drawingGroup()
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
