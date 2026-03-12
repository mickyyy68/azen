// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "aZen",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "aZen",
            path: "Sources/aZen",
            exclude: ["Resources/Info.plist"]
        )
    ]
)
