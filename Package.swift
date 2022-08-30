// swift-tools-version:5.6
import PackageDescription

// When developing Pamphlet, change this to include os(macOS).
// When ready to release, run "make release" to build the latest
// Pamphlet tool and embed it in a artifactbundle, and change this
// back to just os(Linux)
#if os(Linux)
let productsTarget: [PackageDescription.Product] = [
    .executable(name: "PamphletTool", targets: ["PamphletTool"]),
]
let pluginTarget: [PackageDescription.Target] = [
    .executableTarget(
        name: "PamphletTool",
        dependencies: [
            "Hitch",
            "PamphletFramework",
            .product(name: "ArgumentParser", package: "swift-argument-parser")
        ]
    )
]
#else
let productsTarget: [PackageDescription.Product] = [
    .library(name: "PamphletTool", targets: ["PamphletTool"]),
]
let pluginTarget: [PackageDescription.Target] = [
    .binaryTarget(name: "PamphletTool",
                  path: "dist/PamphletTool.zip"),
]
#endif

let package = Package(
    name: "Pamphlet",
    platforms: [
        .macOS(.v10_13), .iOS(.v11)
    ],
    products: productsTarget + [
        .library(name: "PamphletFramework", targets: ["PamphletFramework"]),
        .plugin(name: "PamphletPlugin", targets: ["PamphletPlugin"]),
        .plugin(name: "PamphletReleaseOnlyPlugin", targets: ["PamphletReleaseOnlyPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/KittyMac/Jib.git", from: "0.0.2"),
		.package(url: "https://github.com/KittyMac/Hitch.git", from: "0.4.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/1024jp/GzipSwift.git", from: "5.2.0")
    ],
    targets: pluginTarget + [
        .plugin(
            name: "PamphletPlugin",
            capability: .buildTool(),
            dependencies: ["PamphletTool"]
        ),
        .plugin(
            name: "PamphletReleaseOnlyPlugin",
            capability: .buildTool(),
            dependencies: ["PamphletTool"]
        ),
        .target(
            name: "PamphletFramework",
            dependencies: [
                "Hitch",
                "libmcpp",
                "Jib",
                .product(name: "Gzip", package: "GzipSwift"),
            ]
        ),
        .target(
            name: "libmcpp"
        ),
        .testTarget(
            name: "PamphletFrameworkTests",
            dependencies: [
                "PamphletFramework"
            ],
            plugins: [
                .plugin(name: "PamphletPlugin")
            ]
        )
    ]
)
