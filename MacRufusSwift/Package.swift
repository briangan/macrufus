// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacRufusSwift",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "MacRufusSwift",
            path: "Sources/MacRufusSwift"
        )
    ]
)
