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
}
