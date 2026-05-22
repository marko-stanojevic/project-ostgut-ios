// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SinkPlayback",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SinkPlayback", targets: ["SinkPlayback"]),
    ],
    targets: [
        .target(
            name: "SinkPlayback",
            dependencies: [],
            linkerSettings: [
                .linkedFramework("MediaToolbox"),
                .linkedFramework("Accelerate")
            ]
        ),
        .testTarget(
            name: "SinkPlaybackTests",
            dependencies: ["SinkPlayback"]
        ),
    ]
)
