import CoreGraphics
import OSLog

struct SymbolPixelImage {
    let width: Int
    let height: Int
    let bytesPerRow: Int
    let bytesPerPixel: Int
    let data: [UInt8]

    init(width: Int, height: Int, data: [UInt8], bytesPerPixel: Int = 4) {
        self.width = width
        self.height = height
        self.bytesPerPixel = bytesPerPixel
        self.bytesPerRow = width * bytesPerPixel
        self.data = data
    }
}

enum SymbolParticleTargetGenerator {
    private static let logger = Logger(subsystem: "com.andreasink.SymbolParticleMorph", category: "SymbolParticleTargetGenerator")

    private enum Constants {
        static let minimumVisibleAlpha: UInt8 = 50
        static let redLuminanceWeight = 0.299
        static let greenLuminanceWeight = 0.587
        static let blueLuminanceWeight = 0.114
        static let colorChannelMax = 255.0
        static let densityMinimum = 5.0
        static let densityRangeSteps: UInt64 = 1_500
        static let densityScale = 100.0
        static let xDensityPrime = 73_856_093
        static let yDensityPrime = 19_349_663
    }

    @MainActor
    static func targets(
        for symbolName: String,
        in size: CGSize,
        configuration: ParticleMorphConfiguration
    ) -> [SymbolParticle] {
        let renderSize = CGSize(
            width: configuration.symbolPointSize,
            height: configuration.symbolPointSize
        )
        guard let cgImage = SymbolImageCache.shared.image(
            for: symbolName,
            size: renderSize,
            configuration: configuration
        ) else {
            logger.warning("Failed to rasterize SF Symbol '\(symbolName, privacy: .public)'")
            return []
        }

        let targets = targets(from: cgImage, in: size, configuration: configuration)
        if targets.isEmpty {
            logger.debug("Generated no particle targets for SF Symbol '\(symbolName, privacy: .public)'")
        }
        return targets
    }

    static func targets(
        from cgImage: CGImage,
        in size: CGSize,
        configuration: ParticleMorphConfiguration
    ) -> [SymbolParticle] {
        guard let dataProvider = cgImage.dataProvider,
              let pixelData = dataProvider.data else {
            return []
        }

        let data = CFDataGetBytePtr(pixelData)
        let byteCount = CFDataGetLength(pixelData)
        let bytesPerPixel = max(1, cgImage.bitsPerPixel / 8)
        var bytes = [UInt8]()
        if let data {
            bytes = Array(UnsafeBufferPointer(start: data, count: byteCount))
        }

        let pixelImage = SymbolPixelImage(
            width: cgImage.width,
            height: cgImage.height,
            data: bytes,
            bytesPerPixel: bytesPerPixel
        )
        return targets(
            from: pixelImage,
            in: size,
            configuration: configuration,
            bytesPerRow: cgImage.bytesPerRow
        )
    }

    static func targets(
        from image: SymbolPixelImage,
        in size: CGSize,
        configuration: ParticleMorphConfiguration,
        bytesPerRow: Int? = nil
    ) -> [SymbolParticle] {
        guard image.width > 0, image.height > 0 else { return [] }
        guard size.width > 0, size.height > 0 else { return [] }
        guard image.bytesPerPixel >= 4 else { return [] }

        var targets: [SymbolParticle] = []
        let sampledColumnCount = (image.width + configuration.samplingStep - 1) / configuration.samplingStep
        let sampledRowCount = (image.height + configuration.samplingStep - 1) / configuration.samplingStep
        targets.reserveCapacity(min(configuration.maxParticleCount, sampledColumnCount * sampledRowCount))
        let maxParticleSize = max(
            configuration.particleSizeRange.lowerBound,
            configuration.particleSizeRange.upperBound
        )
        let inset = Double(configuration.contentInset) + maxParticleSize / 2
        let drawableWidth = max(1, Double(size.width) - inset * 2)
        let drawableHeight = max(1, Double(size.height) - inset * 2)
        let scale = min(
            drawableWidth / Double(image.width),
            drawableHeight / Double(image.height)
        )
        let offsetX = inset + (drawableWidth - Double(image.width) * scale) / 2.0
        let offsetY = inset + (drawableHeight - Double(image.height) * scale) / 2.0
        let rowStride = bytesPerRow ?? image.bytesPerRow
        guard rowStride >= image.width * image.bytesPerPixel else { return [] }

        for y in stride(from: 0, to: image.height, by: configuration.samplingStep) {
            for x in stride(from: 0, to: image.width, by: configuration.samplingStep) {
                let pixelIndex = y * rowStride + x * image.bytesPerPixel
                guard pixelIndex + 3 < image.data.count else { continue }

                let r = image.data[pixelIndex]
                let g = image.data[pixelIndex + 1]
                let b = image.data[pixelIndex + 2]
                let a = image.data[pixelIndex + 3]
                guard a > Constants.minimumVisibleAlpha else { continue }

                let brightness = (
                    Constants.redLuminanceWeight * Double(r)
                    + Constants.greenLuminanceWeight * Double(g)
                    + Constants.blueLuminanceWeight * Double(b)
                ) / Constants.colorChannelMax
                let px = Double(x) * scale + offsetX
                let py = Double(y) * scale + offsetY
                let depth = 1 - brightness
                targets.append(
                    SymbolParticle(
                        x: px,
                        y: py,
                        baseX: px,
                        baseY: py,
                        density: density(forX: x, y: y),
                        z: depth,
                        color: SymbolParticleColor(
                            red: Double(r) / Constants.colorChannelMax,
                            green: Double(g) / Constants.colorChannelMax,
                            blue: Double(b) / Constants.colorChannelMax,
                            opacity: Double(a) / Constants.colorChannelMax
                        )
                    )
                )
            }
        }

        return capped(targets, maxCount: configuration.maxParticleCount)
    }

    private static func capped(_ targets: [SymbolParticle], maxCount: Int) -> [SymbolParticle] {
        guard targets.count > maxCount else { return targets }
        let step = max(1, targets.count / maxCount)
        let reduced = stride(from: 0, to: targets.count, by: step).map { targets[$0] }
        if reduced.count > maxCount {
            return Array(reduced.prefix(maxCount))
        }
        return reduced
    }

    private static func density(forX x: Int, y: Int) -> Double {
        let mixed = UInt64((x &* Constants.xDensityPrime) ^ (y &* Constants.yDensityPrime))
        return Constants.densityMinimum + Double(mixed % Constants.densityRangeSteps) / Constants.densityScale
    }
}
