// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Secretary",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Secretary", targets: ["Secretary"])
    ],
    dependencies: [
        // No external dependencies for now to keep it self-contained.
        // We will use native APIs for everything.
    ],
    targets: [
        .executableTarget(
            name: "Secretary",
            dependencies: [],
            path: "SecretaryApp/Sources",
            resources: [
                .process("../Resources")
            ]
        )
    ]
)
