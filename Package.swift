// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Halo",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Halo",
            path: "Sources/Halo",
            resources: [
                .process("Resources"),
            ],
            linkerSettings: [
                .linkedFramework("Cocoa"),
                .linkedFramework("SpriteKit"),
            ]
        )
    ]
)
