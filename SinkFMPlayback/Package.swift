// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SinkFMPlayback",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SinkFMPlayback", targets: ["SinkFMPlayback"]),
    ],
    targets: [
        .target(
            name: "SinkFMPlayback",
            dependencies: []
        ),
        .testTarget(
            name: "SinkFMPlaybackTests",
            dependencies: ["SinkFMPlayback"]
        ),
    ]
)
