// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AlmondCore",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "AlmondCore", targets: ["AlmondCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-markdown.git", from: "0.3.0"),
    ],
    targets: [
        .target(
            name: "AlmondCore",
            dependencies: [.product(name: "Markdown", package: "swift-markdown")],
            path: "Sources/AlmondCore"
        ),
        .testTarget(
            name: "AlmondCoreTests",
            dependencies: ["AlmondCore"],
            path: "Tests/AlmondCoreTests"
        ),
    ]
)
