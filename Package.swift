// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "streamer-backend",
    platforms: [
       .macOS(.v12)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.85.0"),
        .package(url: "https://github.com/vapor/redis.git", from: "4.0.0"),
        .package(path: "Resolver"),
        .package(url: "https://github.com/dankinsoid/swift-log-loki.git", from: "1.10.0"),
        .package(url: "https://github.com/swift-server-community/SwiftPrometheus.git", from: "1.0.2"),
        .package(url: "https://github.com/vapor/jwt-kit.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/leaf.git", from: "4.0.0")

    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Resolver", package: "Resolver"),
                .product(name: "Redis", package: "redis"),
                .product(name: "LoggingLoki", package: "swift-log-loki"),
                .product(name: "JWTKit", package: "jwt-kit"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "Leaf", package: "leaf"),
                "SwiftPrometheus"
            ]
        ),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor")
        ])
    ]
)
