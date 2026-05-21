// swift-tools-version: 5.9
import PackageDescription

// Swift OpenAPI Generator plugin and runtime dependencies are wired in ios-6.
// This package currently provides the openapi.yaml spec and the APIClient stub.
let package = Package(
    name: "SinkAPI",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SinkAPI", targets: ["SinkAPI"]),
    ],
    targets: [
        .target(
            name: "SinkAPI",
            dependencies: []
        ),
        .testTarget(
            name: "SinkAPITests",
            dependencies: ["SinkAPI"]
        ),
    ]
)
