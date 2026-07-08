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
            primaryColor: .systemBlue,
            secondaryColor: .secondaryGray,
            symbolPointSize: 80
        )
        let differentStyle = SymbolImageCacheKey(
            symbolName: "hand.thumbsup",
            width: 80,
            height: 80,
            scale: 2,
            renderingStyle: .palette,
            primaryColor: .systemBlue,
            secondaryColor: .secondaryGray,
            symbolPointSize: 80
        )
        let differentSize = SymbolImageCacheKey(
            symbolName: "hand.thumbsup",
            width: 120,
            height: 120,
            scale: 2,
            renderingStyle: .hierarchical,
            primaryColor: .systemBlue,
            secondaryColor: .secondaryGray,
            symbolPointSize: 80
        )
        let differentPointSize = SymbolImageCacheKey(
            symbolName: "hand.thumbsup",
            width: 80,
            height: 80,
            scale: 2,
            renderingStyle: .hierarchical,
            primaryColor: .systemBlue,
            secondaryColor: .secondaryGray,
            symbolPointSize: 96
        )
        let differentPrimaryColor = SymbolImageCacheKey(
            symbolName: "hand.thumbsup",
            width: 80,
            height: 80,
            scale: 2,
            renderingStyle: .hierarchical,
            primaryColor: SymbolParticleColor(red: 1, green: 0.2, blue: 0.1),
            secondaryColor: .secondaryGray,
            symbolPointSize: 80
        )
        let differentSecondaryColor = SymbolImageCacheKey(
            symbolName: "hand.thumbsup",
            width: 80,
            height: 80,
            scale: 2,
            renderingStyle: .hierarchical,
            primaryColor: .systemBlue,
            secondaryColor: SymbolParticleColor(red: 0.1, green: 0.9, blue: 0.4),
            symbolPointSize: 80
        )

        #expect(base != differentStyle)
        #expect(base != differentSize)
        #expect(base != differentPointSize)
        #expect(base != differentPrimaryColor)
        #expect(base != differentSecondaryColor)
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
