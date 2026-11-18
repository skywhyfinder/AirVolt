// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AirVolt",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "AirVolt", targets: ["AirVolt"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "AirVolt",
            dependencies: [],
            path: "Sources/AirVolt",
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("GameController"),
                .linkedFramework("IOBluetooth"),
                .linkedFramework("UserNotifications"),
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI")
            ]
        )
    ]
)
