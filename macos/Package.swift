// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "FlashcardMac",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(path: "../Shared")
    ],
    targets: [
        .executableTarget(
            name: "FlashcardMac",
            dependencies: [
                .product(name: "FlashcardShared", package: "Shared")
            ],
            path: "Sources/Flashcard"
        )
    ]
)
