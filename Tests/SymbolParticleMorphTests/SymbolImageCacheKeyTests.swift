import CoreGraphics
import Testing
@testable import SymbolParticleMorph

@Suite
struct SymbolImageCacheKeyTests {
    @Test
    func cacheKeysIncludeRenderingConfiguration() {
        let base = SymbolImageCacheKey(
            symbolName: "hand.thumbsup",
            width: 80,
            height: 80,
            scale: 2,
            renderingStyle: .hierarchical,
            symbolPointSize: 80
        )
        let differentStyle = SymbolImageCacheKey(
            symbolName: "hand.thumbsup",
            width: 80,
            height: 80,
            scale: 2,
            renderingStyle: .palette,
            symbolPointSize: 80
        )
        let differentSize = SymbolImageCacheKey(
            symbolName: "hand.thumbsup",
            width: 120,
            height: 120,
            scale: 2,
            renderingStyle: .hierarchical,
            symbolPointSize: 80
        )
        let differentPointSize = SymbolImageCacheKey(
            symbolName: "hand.thumbsup",
            width: 80,
            height: 80,
            scale: 2,
            renderingStyle: .hierarchical,
            symbolPointSize: 96
        )

        #expect(base != differentStyle)
        #expect(base != differentSize)
        #expect(base != differentPointSize)
    }

    @MainActor
    @Test
    func cacheEvictsEntriesAboveConfiguredLimit() {
        let cache = SymbolImageCache(maxEntryCount: 2)
        let configuration = ParticleMorphConfiguration(quality: .compact)

        _ = cache.image(
            for: "hand.thumbsup",
            size: CGSize(width: 64, height: 64),
            configuration: configuration
        )
        _ = cache.image(
            for: "hand.thumbsup",
            size: CGSize(width: 65, height: 65),
            configuration: configuration
        )
        _ = cache.image(
            for: "hand.thumbsup",
            size: CGSize(width: 66, height: 66),
            configuration: configuration
        )

        #expect(cache.count <= 2)
    }

    @MainActor
    @Test
    func clearRemovesAllCachedEntries() {
        let cache = SymbolImageCache(maxEntryCount: 2)
        let configuration = ParticleMorphConfiguration(quality: .compact)

        _ = cache.image(
            for: "hand.thumbsup",
            size: CGSize(width: 64, height: 64),
            configuration: configuration
        )

        cache.clear()

        #expect(cache.count == 0)
    }

    @MainActor
    @Test
    func rasterizedSymbolImageIsNonBlank() throws {
        let cache = SymbolImageCache(maxEntryCount: 2)
        let configuration = ParticleMorphConfiguration(quality: .compact)

        let image = try #require(
            cache.image(
                for: "hand.thumbsup",
                size: CGSize(width: 64, height: 64),
                configuration: configuration
            )
        )

        #expect(nonTransparentPixelCount(in: image) > 0)
    }

    private func nonTransparentPixelCount(in image: CGImage) -> Int {
        guard let dataProvider = image.dataProvider,
              let pixelData = dataProvider.data,
              let data = CFDataGetBytePtr(pixelData) else {
            return 0
        }

        let byteCount = CFDataGetLength(pixelData)
        let bytes = UnsafeBufferPointer(start: data, count: byteCount)
        let bytesPerPixel = max(1, image.bitsPerPixel / 8)
        guard bytesPerPixel >= 4 else { return 0 }

        var count = 0
        for y in 0..<image.height {
            for x in 0..<image.width {
                let pixelIndex = y * image.bytesPerRow + x * bytesPerPixel
                guard pixelIndex + 3 < byteCount else { continue }
                if bytes[pixelIndex + 3] > 0 {
                    count += 1
                }
            }
        }
        return count
    }
}
