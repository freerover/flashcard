// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "FlashcardShared",
    platforms: [.macOS(.v13), .iOS(.v17)],
    products: [
        .library(name: "FlashcardShared", targets: ["FlashcardShared"])
    ],
    targets: [
        .target(name: "FlashcardShared")
    ]
)
