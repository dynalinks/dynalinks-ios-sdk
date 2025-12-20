// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "DynalinksSDK",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "DynalinksSDK",
            targets: ["DynalinksSDK"]
        )
    ],
    targets: [
        .target(
            name: "DynalinksSDK",
            dependencies: [],
            path: "Sources/DynalinksSDK"
        ),
        .testTarget(
            name: "DynalinksSDKTests",
            dependencies: ["DynalinksSDK"],
            path: "Tests/DynalinksSDKTests"
        )
    ]
)
