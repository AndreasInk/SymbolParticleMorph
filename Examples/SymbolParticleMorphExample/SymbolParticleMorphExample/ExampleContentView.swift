import SwiftUI
import SymbolParticleMorph

struct ExampleContentView: View {
    @State private var selectedSymbolName = "hand.thumbsup"
    @State private var customSymbolName = ""
    @State private var quality: ParticleMorphQuality = .balanced
    @State private var renderingStyle: SymbolParticleRenderingStyle = .palette
    @State private var colorTheme: DemoColorTheme = .sunset
    @State private var symbolPointSize = 94.0
    @State private var contentInset = 10.0
    @State private var maxParticleCount = 1_800.0
    @State private var samplingStep = 4.0
    @State private var frameBudget = 54.0
    @State private var revealDuration = 0.8

    private let symbols = DemoSymbol.defaultSymbols

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 10) {
                    SymbolParticleMorph(
                        symbolName: selectedSymbolName,
                        configuration: configuration
                    )
                    .frame(width: 250, height: 250)
                    .accessibilityLabel(selectedSymbolName)

                    Text(selectedSymbolName)
                        .font(.callout.monospaced())
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 16) {
                    symbolPicker
                    customSymbolField
                    styleControls
                    colorControls
                    particleControls
                    animationControls
                }
                .frame(maxWidth: 520)
            }
            .padding(24)
        }
    }

    private var configuration: ParticleMorphConfiguration {
        ParticleMorphConfiguration(
            quality: quality,
            maxParticleCount: Int(maxParticleCount),
            samplingStep: Int(samplingStep),
            contentInset: CGFloat(contentInset),
            revealDuration: revealDuration,
            frameBudget: Int(frameBudget),
            renderingStyle: renderingStyle,
            primaryColor: colorTheme.primaryColor,
            secondaryColor: colorTheme.secondaryColor,
            symbolPointSize: CGFloat(symbolPointSize)
        )
    }

    private var symbolPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Symbols")
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                ForEach(symbols) { symbol in
                    Button {
                        selectedSymbolName = symbol.name
                        customSymbolName = symbol.name
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: symbol.name)
                                .font(.title2)
                            Text(symbol.title)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                    }
                    .buttonStyle(.bordered)
                    .tint(selectedSymbolName == symbol.name ? colorTheme.primarySwiftUIColor : .secondary)
                }
            }
        }
    }

    private var customSymbolField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Custom SF Symbol")
                .font(.headline)

            HStack(spacing: 10) {
                TextField("heart.circle.fill", text: $customSymbolName)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(applyCustomSymbol)

                Button("Apply", action: applyCustomSymbol)
                    .buttonStyle(.borderedProminent)
                    .tint(colorTheme.primarySwiftUIColor)
            }
        }
    }

    private var styleControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Style")
                .font(.headline)

            Picker("Rendering", selection: $renderingStyle) {
                ForEach(SymbolParticleRenderingStyle.allCases, id: \.self) { style in
                    Text(style.rawValue.capitalized)
                        .tag(style)
                }
            }
            .pickerStyle(.segmented)

            Picker("Quality", selection: $quality) {
                ForEach(ParticleMorphQuality.allCases, id: \.self) { quality in
                    Text(quality.rawValue.capitalized)
                        .tag(quality)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var colorControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Color Theme")
                .font(.headline)

            Picker("Color Theme", selection: $colorTheme) {
                ForEach(DemoColorTheme.allCases) { theme in
                    HStack {
                        Text(theme.title)
                        Spacer()
                        Circle()
                            .fill(theme.primarySwiftUIColor)
                            .frame(width: 12, height: 12)
                        Circle()
                            .fill(theme.secondarySwiftUIColor)
                            .frame(width: 12, height: 12)
                    }
                    .tag(theme)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var particleControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Particles")
                .font(.headline)

            sliderRow(
                title: "Max particles",
                value: $maxParticleCount,
                range: 400...4_000,
                step: 100,
                display: "\(Int(maxParticleCount))"
            )
            sliderRow(
                title: "Sampling step",
                value: $samplingStep,
                range: 1...10,
                step: 1,
                display: "\(Int(samplingStep))"
            )
            sliderRow(
                title: "Symbol size",
                value: $symbolPointSize,
                range: 40...140,
                step: 2,
                display: "\(Int(symbolPointSize))"
            )
            sliderRow(
                title: "Inset",
                value: $contentInset,
                range: 0...32,
                step: 1,
                display: "\(Int(contentInset))"
            )
        }
    }

    private var animationControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Animation")
                .font(.headline)

            sliderRow(
                title: "Frame budget",
                value: $frameBudget,
                range: 0...120,
                step: 6,
                display: "\(Int(frameBudget))"
            )
            sliderRow(
                title: "Reveal duration",
                value: $revealDuration,
                range: 0...2,
                step: 0.1,
                display: String(format: "%.1fs", revealDuration)
            )
        }
    }

    private func sliderRow(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        display: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(display)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: value, in: range, step: step)
        }
    }

    private func applyCustomSymbol() {
        let trimmed = customSymbolName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        selectedSymbolName = trimmed
    }
}

private struct DemoSymbol: Identifiable {
    let name: String
    let title: String

    var id: String { name }

    static let defaultSymbols = [
        DemoSymbol(name: "hand.thumbsup", title: "Up"),
        DemoSymbol(name: "hand.thumbsdown", title: "Down"),
        DemoSymbol(name: "heart.circle.fill", title: "Heart"),
        DemoSymbol(name: "star.circle.fill", title: "Star"),
        DemoSymbol(name: "bell.badge.fill", title: "Bell"),
        DemoSymbol(name: "cloud.sun.rain.fill", title: "Weather"),
        DemoSymbol(name: "speaker.wave.3.fill", title: "Sound"),
        DemoSymbol(name: "person.crop.circle.badge.plus", title: "Person"),
    ]
}

private enum DemoColorTheme: String, CaseIterable, Identifiable {
    case ocean
    case sunset
    case mint
    case grape
    case graphite

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ocean: "Ocean"
        case .sunset: "Sunset"
        case .mint: "Mint"
        case .grape: "Grape"
        case .graphite: "Graphite"
        }
    }

    var primaryColor: SymbolParticleColor {
        switch self {
        case .ocean: SymbolParticleColor(red: 0.0, green: 0.48, blue: 1.0)
        case .sunset: SymbolParticleColor(red: 1.0, green: 0.34, blue: 0.16)
        case .mint: SymbolParticleColor(red: 0.0, green: 0.78, blue: 0.55)
        case .grape: SymbolParticleColor(red: 0.58, green: 0.31, blue: 0.94)
        case .graphite: SymbolParticleColor(red: 0.22, green: 0.23, blue: 0.25)
        }
    }

    var secondaryColor: SymbolParticleColor {
        switch self {
        case .ocean: SymbolParticleColor(red: 0.18, green: 0.68, blue: 1.0)
        case .sunset: SymbolParticleColor(red: 1.0, green: 0.52, blue: 0.30)
        case .mint: SymbolParticleColor(red: 0.23, green: 0.88, blue: 0.68)
        case .grape: SymbolParticleColor(red: 0.72, green: 0.48, blue: 1.0)
        case .graphite: SymbolParticleColor(red: 0.45, green: 0.46, blue: 0.49)
        }
    }

    var primarySwiftUIColor: Color {
        Color(primaryColor)
    }

    var secondarySwiftUIColor: Color {
        Color(secondaryColor)
    }
}

private extension Color {
    init(_ color: SymbolParticleColor) {
        self.init(red: color.red, green: color.green, blue: color.blue, opacity: color.opacity)
    }
}

#Preview {
    ExampleContentView()
}
