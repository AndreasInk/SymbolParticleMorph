import CoreGraphics
import SwiftUI

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
            return []
        }

        return targets(from: cgImage, in: size, configuration: configuration)
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
        let inset = Double(configuration.contentInset)
        let drawableWidth = max(1, Double(size.width) - inset * 2)
        let drawableHeight = max(1, Double(size.height) - inset * 2)
        let scale = min(
            drawableWidth / Double(image.width),
            drawableHeight / Double(image.height)
        )
        let offsetX = inset + (drawableWidth - Double(image.width) * scale) / 2.0
        let offsetY = inset + (drawableHeight - Double(image.height) * scale) / 2.0
        let rowStride = bytesPerRow ?? image.bytesPerRow

        for y in stride(from: 0, to: image.height, by: configuration.samplingStep) {
            for x in stride(from: 0, to: image.width, by: configuration.samplingStep) {
                let pixelIndex = y * rowStride + x * image.bytesPerPixel
                guard pixelIndex + 3 < image.data.count else { continue }

                let r = image.data[pixelIndex]
                let g = image.data[pixelIndex + 1]
                let b = image.data[pixelIndex + 2]
                let a = image.data[pixelIndex + 3]
                guard a > 50 else { continue }

                let brightness = (0.299 * Double(r) + 0.587 * Double(g) + 0.114 * Double(b)) / 255.0
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
                        color: Color(
                            red: Double(r) / 255,
                            green: Double(g) / 255,
                            blue: Double(b) / 255,
                            opacity: Double(a) / 255
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
        let mixed = UInt64((x &* 73_856_093) ^ (y &* 19_349_663))
        return 5 + Double(mixed % 1_500) / 100
    }
}
