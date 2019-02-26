// swift-tools-version:4.1
import PackageDescription

let package = Package(
    name: "DBus",
    products: [
        .library(name: "DBus", targets: ["DBus"]),
        .executable(name: "DBusClient", targets: ["DBusClient"]),
    ],
    dependencies: [
        .package( url: "https://github.com/taborkelly/CDBus.git", .branch("master"))
    ],
    targets: [
        .target(
            name: "DBus",
            dependencies: [ ]
        ),
        .target(
            name: "DBusClient",
            dependencies: [ "DBus" ]
        ),
        .testTarget(
            name: "DBusTests",
            dependencies: ["DBus"]
        )
    ],
    swiftLanguageVersions: [4]
)
