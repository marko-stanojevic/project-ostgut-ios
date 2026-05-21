// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SinkPlayback",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SinkPlayback", targets: ["SinkPlayback"]),
    ],
    targets: [
        .target(
            name: "SinkPlayback",
            dependencies: []
        ),
        .testTarget(
            name: "SinkPlaybackTests",
            dependencies: ["SinkPlayback"]
        ),
    ]
)
