// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SinkAPI",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "SinkAPI", targets: ["SinkAPI"]),
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
        .package(
            url: "https://github.com/apple/swift-http-types",
            from: "1.0.0"
        ),
    ],
    targets: [
        .target(
            name: "SinkAPI",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
                .product(name: "HTTPTypes", package: "swift-http-types"),
            ],
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator"),
            ]
        ),
        .testTarget(
            name: "SinkAPITests",
            dependencies: ["SinkAPI"]
        ),
    ]
)
