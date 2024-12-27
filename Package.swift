// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "OpenAIRealtimeAPI",
    platforms: [
        .iOS(.v13), .macOS(.v11)
    ],
    products: [
        .library(
            name: "OpenAIRealtimeAPI",
            targets: ["OpenAIRealtimeAPI"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "OpenAIRealtimeAPI",
            dependencies: []
        ),
        .testTarget(
            name: "OpenAIRealtimeAPITests",
            dependencies: ["OpenAIRealtimeAPI"]
        ),
    ]
)
