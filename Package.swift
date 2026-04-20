// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "JamesViewerCore",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "JamesViewerCore", targets: ["JamesViewerCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-markdown.git", from: "0.3.0"),
    ],
    targets: [
        .target(
            name: "JamesViewerCore",
            dependencies: [.product(name: "Markdown", package: "swift-markdown")],
            path: "Sources/JamesViewerCore"
        ),
        .testTarget(
            name: "JamesViewerCoreTests",
            dependencies: ["JamesViewerCore"],
            path: "Tests/JamesViewerCoreTests"
        ),
    ]
)
