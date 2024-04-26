// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "streamer-backend",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.85.0"),
        .package(url: "https://github.com/vapor/redis.git", from: "4.0.0"),
        .package(url: "https://github.com/dankinsoid/swift-log-loki.git", from: "1.10.0"),
        .package(url: "https://github.com/swift-server-community/SwiftPrometheus.git", from: "1.0.2"),
        .package(url: "https://github.com/vapor/jwt-kit.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/leaf.git", from: "4.0.0"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.3.4"),
        .package(url: "https://github.com/ChanTsune/SwiftyPyString.git", from: "2.2.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMajor(from: "1.4.3")),
        .package(url: "https://github.com/theonlymo/TMDb.git", branch: "main"),
        .package(path: "Resolver")
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
                "SwiftPrometheus",
                "Resolver"
            ]
        ),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor")
        ])
    ]
)
