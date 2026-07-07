// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Flashcard",
    platforms: [.macOS(.v13), .iOS(.v17)],
    dependencies: [
        .package(path: "../Shared")
    ],
    targets: [
        .executableTarget(
            name: "Flashcard",
            dependencies: [
                .product(name: "FlashcardShared", package: "Shared")
            ],
            path: "Sources/Flashcard"
        )
    ]
)
