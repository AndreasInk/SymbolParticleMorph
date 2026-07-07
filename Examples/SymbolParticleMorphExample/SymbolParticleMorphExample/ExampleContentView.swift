import SwiftUI
import SymbolParticleMorph

struct ExampleContentView: View {
    @State private var isPositive = true
    @State private var quality: ParticleMorphQuality = .balanced
    @State private var renderingStyle: SymbolParticleRenderingStyle = .hierarchical

    var body: some View {
        VStack(spacing: 28) {
            SymbolParticleMorph(
                symbolName: isPositive ? "hand.thumbsup" : "hand.thumbsdown",
                configuration: ParticleMorphConfiguration(
                    quality: quality,
                    renderingStyle: renderingStyle
                )
            )
            .frame(width: 240, height: 240)
            .accessibilityLabel(isPositive ? "Thumbs up" : "Thumbs down")

            VStack(spacing: 14) {
                Toggle("Positive", isOn: $isPositive)
                    .toggleStyle(.switch)

                Picker("Quality", selection: $quality) {
                    ForEach(ParticleMorphQuality.allCases, id: \.self) { quality in
                        Text(quality.rawValue.capitalized)
                            .tag(quality)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Rendering", selection: $renderingStyle) {
                    ForEach(SymbolParticleRenderingStyle.allCases, id: \.self) { style in
                        Text(style.rawValue.capitalized)
                            .tag(style)
                    }
                }
                .pickerStyle(.segmented)
            }
            .frame(maxWidth: 420)
        }
        .padding(28)
    }
}

#Preview {
    ExampleContentView()
}
