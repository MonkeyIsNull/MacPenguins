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
                "LegacyCompat.swift",
                "SimplePenguin.swift",
                "SimpleCollision.swift",
                "SimpleWindowManager.swift",
                "BasicRenderer.swift",
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