# SymbolParticleMorph

`SymbolParticleMorph` is a SwiftUI package that renders SF Symbols as animated particle fields and morphs the particles when the symbol changes. It started as the thumbs-up/thumbs-down symbol morph used in PodPosture, but the package API is generic and app independent.

Licensed under the MIT License.

## Used In

- [PodPosture - Posture Improver](https://apps.apple.com/us/app/podposture-posture-improver/id1550684595) uses `SymbolParticleMorph` for its onboarding and posture-state SF Symbol particle glyphs.

https://github.com/user-attachments/assets/f7c99376-702b-476c-b236-97378780ef2e

## Platform Support

- iOS 18+
- macOS 15+
- Swift 6.1+

The package uses SwiftUI `Canvas` and `ImageRenderer`.

## Installation

Add the package with Swift Package Manager:

```swift
.package(url: "https://github.com/AndreasInk/SymbolParticleMorph.git", from: "0.1.4")
```

Then add `SymbolParticleMorph` to your app target.

## Quick Start

```swift
import SwiftUI
import SymbolParticleMorph

struct ThumbToggle: View {
    @State private var liked = true

    var body: some View {
        Button {
            liked.toggle()
        } label: {
            SymbolParticleMorph(
                symbolName: liked ? "hand.thumbsup" : "hand.thumbsdown",
                configuration: ParticleMorphConfiguration(quality: .balanced)
            )
            .frame(width: 220, height: 220)
            .accessibilityLabel(liked ? "Positive" : "Negative")
        }
        .buttonStyle(.plain)
    }
}
```

## Compact Glyph

```swift
SymbolParticleMorph(
    symbolName: "figure.stand",
    configuration: ParticleMorphConfiguration(quality: .compact, contentInset: 4)
)
.frame(width: 56, height: 56)
.accessibilityHidden(true)
```

## Configuration

`ParticleMorphConfiguration` controls:

- `maxParticleCount`: upper bound for sampled particles.
- `samplingStep`: pixel stride used while sampling the rasterized symbol.
- `contentInset`: padding before mapping particles into the view.
- `particleSizeRange`: rendered particle size range.
- `revealDuration`: initial reveal animation duration.
- `frameBudget`: number of timer ticks after each symbol change.
- `frameRate`: requested animation frame rate.
- `renderingStyle`: `.hierarchical`, `.monochrome`, or `.palette`.
- `symbolPointSize`: size used while rasterizing the SF Symbol.

Use `.compact` for small status glyphs, `.balanced` for medium icon art, and `.detailed` for large hero glyphs.

## Performance Notes

Particle count is the main cost driver. Prefer `.compact` for toolbar or status glyphs, and keep detailed morphs on larger static surfaces. The package caches rasterized SF Symbols by symbol name, render size, scale, rendering style, and point size. You can warm the cache:

```swift
await MainActor.run {
    SymbolParticleMorphCache.preload(
        symbols: ["hand.thumbsup", "hand.thumbsdown", "figure.stand"],
        configuration: ParticleMorphConfiguration(quality: .compact)
    )
}
```

## Accessibility

The view honors the system Reduce Motion setting by skipping the motion ticks and rendering the stable particle shape. Add an accessibility label at the call site when the symbol communicates state.

## Privacy

The package performs no networking, analytics, tracking, persistence, or remote writes.

## Troubleshooting

- Blank output usually means the SF Symbol name is invalid or the frame is zero-sized.
- Choppy animation usually means the particle cap is too high for the surface. Try `.compact` or increase `samplingStep`.
- If colors look unexpected, try a different `renderingStyle`.

## License

`SymbolParticleMorph` is available under the MIT License. See [LICENSE](LICENSE).
