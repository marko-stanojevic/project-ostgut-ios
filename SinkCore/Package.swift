// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SinkCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SinkCore", targets: ["SinkCore"]),
    ],
    dependencies: [
        .package(name: "SinkAPI", path: "../SinkAPI"),
        .package(name: "SinkPlayback", path: "../SinkPlayback"),
    ],
    targets: [
        .target(
            name: "SinkCore",
            dependencies: ["SinkAPI", "SinkPlayback"]
        ),
        .testTarget(
            name: "SinkCoreTests",
            dependencies: ["SinkCore"]
        ),
    ]
)
