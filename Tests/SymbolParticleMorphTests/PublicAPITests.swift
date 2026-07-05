import CoreGraphics
import SwiftUI
import Testing
import SymbolParticleMorph

@Suite
struct PublicAPITests {
    @MainActor
    @Test
    func publicAPICompilesAndCacheCanPreload() {
        let configuration = ParticleMorphConfiguration(
            quality: .compact,
            renderingStyle: .palette
        )

        SymbolParticleMorphCache.clear()
        SymbolParticleMorphCache.preload(
            symbols: ["hand.thumbsup"],
            size: CGSize(width: 64, height: 64),
            configuration: configuration
        )

        let view = SymbolParticleMorph(
            symbolName: "hand.thumbsdown",
            configuration: configuration
        )

        #expect(type(of: view) == SymbolParticleMorph.self)
    }
}
