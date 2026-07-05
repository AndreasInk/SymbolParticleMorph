// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "SymbolParticleMorph",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "SymbolParticleMorph",
            targets: ["SymbolParticleMorph"]
        ),
    ],
    targets: [
        .target(
            name: "SymbolParticleMorph"
        ),
        .testTarget(
            name: "SymbolParticleMorphTests",
            dependencies: ["SymbolParticleMorph"]
        ),
    ]
)
