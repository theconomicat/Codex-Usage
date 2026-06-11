// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Codex-Usage",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "CodexUsage", targets: ["CodexUsage"]),
        .library(name: "CodexUsageCore", targets: ["CodexUsageCore"])
    ],
    targets: [
        .target(name: "CodexUsageCore"),
        .executableTarget(
            name: "CodexUsage",
            dependencies: ["CodexUsageCore"]
        ),
        .testTarget(
            name: "CodexUsageTests",
            dependencies: ["CodexUsageCore"]
        )
    ]
)
