// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Halo",
    platforms: [.macOS(.v13)],
    targets: [
        // Shared, testable logic (no UI dependencies)
        .target(
            name: "HaloCore",
            path: "Sources/HaloCore"
        ),
        // App entry point + UI
        .executableTarget(
            name: "Halo",
            dependencies: ["HaloCore"],
            path: "Sources/Halo",
            resources: [
                .process("Resources"),
            ],
            linkerSettings: [
                .linkedFramework("Cocoa"),
                .linkedFramework("SpriteKit"),
            ]
        ),
        // Tests
        .testTarget(
            name: "HaloCoreTests",
            dependencies: ["HaloCore"],
            path: "Tests/HaloCoreTests"
        ),
    ]
)
