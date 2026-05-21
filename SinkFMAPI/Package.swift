// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SinkFMAPI",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SinkFMAPI", targets: ["SinkFMAPI"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-openapi-generator",
            from: "1.0.0"
        ),
        .package(
            url: "https://github.com/apple/swift-openapi-runtime",
            from: "1.0.0"
        ),
        .package(
            url: "https://github.com/apple/swift-openapi-urlsession",
            from: "1.0.0"
        ),
    ],
    targets: [
        .target(
            name: "SinkFMAPI",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
            ],
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator"),
            ]
        ),
        .testTarget(
            name: "SinkFMAPITests",
            dependencies: ["SinkFMAPI"]
        ),
    ]
)
