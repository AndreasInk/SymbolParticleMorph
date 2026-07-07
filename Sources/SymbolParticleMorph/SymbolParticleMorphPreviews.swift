import SwiftUI

#if DEBUG
private struct SymbolParticleMorphPreviewCatalog: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                previewRow(
                    title: "Quality",
                    items: [
                        ("Compact", "figure.stand", .init(quality: .compact)),
                        ("Balanced", "hand.thumbsup", .init(quality: .balanced)),
                        ("Detailed", "sparkles", .init(quality: .detailed)),
                    ],
                    frameSize: 120
                )

                previewRow(
                    title: "Rendering",
                    items: [
                        ("Hierarchical", "heart.fill", .init(quality: .balanced, renderingStyle: .hierarchical)),
                        ("Monochrome", "heart.fill", .init(quality: .balanced, renderingStyle: .monochrome)),
                        ("Palette", "heart.fill", .init(quality: .balanced, renderingStyle: .palette)),
                    ],
                    frameSize: 120
                )

                previewRow(
                    title: "Tight Frames",
                    items: [
                        ("Small", "bolt.fill", .init(quality: .compact, contentInset: 2)),
                        ("Inset", "bell.fill", .init(quality: .compact, contentInset: 6)),
                        ("Palette", "person.crop.circle.fill", .init(quality: .compact, renderingStyle: .palette)),
                    ],
                    frameSize: 64
                )
            }
            .padding(24)
        }
        .frame(minWidth: 420, minHeight: 620)
    }

    private func previewRow(
        title: String,
        items: [(String, String, ParticleMorphConfiguration)],
        frameSize: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            HStack(alignment: .top, spacing: 18) {
                ForEach(items, id: \.0) { item in
                    VStack(spacing: 8) {
                        SymbolParticleMorph(symbolName: item.1, configuration: item.2)
                            .frame(width: frameSize, height: frameSize)
                            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))

                        Text(item.0)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: max(frameSize, 100))
                }
            }
        }
    }
}

private struct StaticSymbolParticleMorphPreview: View {
    var body: some View {
        HStack(spacing: 20) {
            SymbolParticleMorph(
                symbolName: "hand.thumbsup",
                configuration: ParticleMorphConfiguration(
                    quality: .balanced,
                    revealDuration: 0,
                    frameBudget: 0
                )
            )
            .frame(width: 140, height: 140)

            SymbolParticleMorph(
                symbolName: "hand.thumbsdown",
                configuration: ParticleMorphConfiguration(
                    quality: .balanced,
                    revealDuration: 0,
                    frameBudget: 0,
                    renderingStyle: .palette
                )
            )
            .frame(width: 140, height: 140)
        }
        .padding(24)
    }
}

#Preview("Symbol Particle Morph Catalog") {
    SymbolParticleMorphPreviewCatalog()
}

#Preview("Static No Animation") {
    StaticSymbolParticleMorphPreview()
}
#endif
