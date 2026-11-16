// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ColorfulSwift",
    platforms: [
        .macOS(.v10_13),
        .iOS(.v12),
        .macCatalyst(.v13),
        .tvOS(.v12),
        .watchOS(.v4),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "Colorful", targets: ["Colorful"]),
    ],
    targets: [
        .target(name: "Colorful"),
        .testTarget(name: "ColorfulTests", dependencies: ["Colorful"]),
    ],
    swiftLanguageModes: [.v6]
)
