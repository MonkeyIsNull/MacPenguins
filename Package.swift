// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MacPenguins",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MacPenguins", targets: ["MacPenguins"])
    ],
    targets: [
        .executableTarget(
            name: "MacPenguins",
            dependencies: [],
            path: "Sources",
            sources: [
                "main.swift",
                "Penguin.swift",
                "PenguinEngine.swift",
                "SimpleWindowManager.swift",
                "SimpleRenderer.swift",
                "CollisionDetector.swift",
                "ThemeManager.swift",
                "MacPenguinsService.swift"
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include")
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("QuartzCore"),
                .linkedFramework("Foundation")
            ]
        )
    ]
)