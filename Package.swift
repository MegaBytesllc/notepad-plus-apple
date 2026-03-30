// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NoteMacPlusPlus",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "NoteMacPlusPlus",
            path: "Sources/NoteMacPlusPlus"
        )
    ]
)
