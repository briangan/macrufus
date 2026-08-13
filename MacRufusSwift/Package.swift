// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacRufusSwift",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(
            url: "https://github.com/swiftlang/swift-subprocess.git",
            branch: "main"
        )
    ],
    targets: [
        .executableTarget(
            name: "MacRufusSwift",
            dependencies: [
                .product(name: "Subprocess", package: "swift-subprocess")
            ],
            path: "Sources/MacRufusSwift"
        )
    ]
)
