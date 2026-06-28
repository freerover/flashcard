// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Flashcard",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "Flashcard", path: "Sources/Flashcard")
    ]
)
