// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "streamer-backend",
    platforms: [
       .macOS(.v12)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.76.0"),
        .package(url: "https://github.com/vapor/redis.git", from: "4.0.0"),
        .package(path: "Resolver"),
        .package(url: "https://github.com/lovetodream/swift-log-loki.git", from: "1.0.0"),
        .package(url: "https://github.com/swift-server-community/SwiftPrometheus.git", from: "1.0.2")

    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Resolver", package: "Resolver"),
                .product(name: "Redis", package: "redis"),
                .product(name: "LoggingLoki", package: "swift-log-loki"),
                "SwiftPrometheus"
            ]
        ),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor")
        ])
    ]
)
