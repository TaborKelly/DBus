// swift-tools-version:4.1
import PackageDescription

let package = Package(
    name: "DBus",
    products: [
        .library(name: "DBus", targets: ["DBus"]),
        .executable(name: "DBusClient", targets: ["DBusClient"]),
    ],
    dependencies: [
        .package(url: "https://github.com/taborkelly/CDBus.git", .branch("master")),
        .package(url: "https://github.com/IBM-Swift/HeliumLogger.git", from: "1.8.0"),
        .package(url: "https://github.com/IBM-Swift/LoggerAPI.git", from: "1.8.0"),
        .package(url: "https://github.com/Flight-School/AnyCodable.git", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "DBus",
            dependencies: ["LoggerAPI"]
        ),
        .target(
            name: "DBusClient",
            dependencies: ["AnyCodable", "DBus", "HeliumLogger", "LoggerAPI"]
        ),
        .testTarget(
            name: "DBusTests",
            dependencies: ["AnyCodable", "DBus", "HeliumLogger", "LoggerAPI"]
        )
    ],
    swiftLanguageVersions: [4]
)
