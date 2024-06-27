// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "Pamphlet",
    platforms: [
        .macOS(.v10_13), .iOS(.v11)
    ],
    products: [
        .executable(name: "PamphletTool", targets: ["PamphletTool"]),
        .library(name: "PamphletFramework", targets: ["PamphletFramework"]),
        .plugin(name: "PamphletPlugin", targets: ["PamphletPlugin"]),
        .plugin(name: "PamphletReleaseOnlyPlugin", targets: ["PamphletReleaseOnlyPlugin"]),
        .plugin(name: "PamphletGzipOnlyPlugin", targets: ["PamphletGzipOnlyPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/KittyMac/Sextant.git", from: "0.4.29"),
        .package(url: "https://github.com/KittyMac/Jib.git", from: "0.0.2"),
		.package(url: "https://github.com/KittyMac/Hitch.git", from: "0.4.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/KittyMac/GzipSwift.git", from: "5.3.6")
    ],
    targets: [
        .executableTarget(
            name: "PamphletTool",
            dependencies: [
                "Hitch",
                "PamphletFramework",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .plugin(
            name: "PamphletPlugin",
            capability: .buildTool(),
            dependencies: [
                "PamphletTool",
            ]
        ),
        .plugin(
            name: "PamphletReleaseOnlyPlugin",
            capability: .buildTool(),
            dependencies: [
                "PamphletTool",
            ]
        ),
        .plugin(
            name: "PamphletGzipOnlyPlugin",
            capability: .buildTool(),
            dependencies: [
                "PamphletTool",
            ]
        ),
        .target(
            name: "PamphletFramework",
            dependencies: [
                "Hitch",
                "libmcpp",
                "Jib",
                "Sextant",
                .product(name: "Gzip", package: "GzipSwift"),
            ]
        ),
        .target(
            name: "libmcpp",
            linkerSettings: [
                .linkedLibrary("swiftCore", .when(platforms: [.windows])),
            ]
        ),
        .testTarget(
            name: "PamphletFrameworkTests",
            dependencies: [
                "PamphletFramework"
            ],
            plugins: [
                .plugin(name: "PamphletGzipOnlyPlugin")
            ]
        )
    ]
)
