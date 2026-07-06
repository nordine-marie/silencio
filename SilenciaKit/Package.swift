// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SilenciaKit",
    platforms: [
        // The package logic is platform-agnostic; the app/extension targets
        // set the real iOS deployment floor (iOS 16, see implementation-plan.md).
        .iOS(.v16), .macOS(.v13),
    ],
    products: [
        .library(name: "SilenciaKit", targets: ["SilenciaKit"]),
    ],
    targets: [
        .target(
            name: "SilenciaKit",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "SilenciaKitTests",
            dependencies: ["SilenciaKit"]
        ),
    ]
)
