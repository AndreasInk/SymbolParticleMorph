import SwiftUI
import SymbolParticleMorph

struct ThumbToggleExample: View {
    @State private var isPositive = true

    var body: some View {
        VStack(spacing: 20) {
            SymbolParticleMorph(
                symbolName: isPositive ? "hand.thumbsup" : "hand.thumbsdown",
                configuration: ParticleMorphConfiguration(quality: .balanced)
            )
            .frame(width: 220, height: 220)
            .accessibilityLabel(isPositive ? "Thumbs up" : "Thumbs down")

            Toggle("Positive", isOn: $isPositive)
                .toggleStyle(.switch)
        }
        .padding()
    }
}

#Preview {
    ThumbToggleExample()
}
