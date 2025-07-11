// swift-tools-version:5.6
import PackageDescription

// When runnning "make release" to build the binary tools change this to true
// Otherwise always set it to false
#if false
let productsTarget: [PackageDescription.Product] = [
    
]
let pluginTarget: [PackageDescription.Target] = [
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
]
#else

var plugins = [
    "PamphletTool-focal-571",
    "PamphletTool-focal-580",
    "PamphletTool-focal-592",
    "PamphletTool-jammy-592",
    "PamphletTool-fedora38-573",
]

#if os(Windows)
plugins += [
    "PamphletTool-windows-592",
]
#endif

var productsTarget: [PackageDescription.Product] = [
    .library(name: "PamphletTool", targets: plugins),
]
var pluginTarget: [PackageDescription.Target] = [
    .binaryTarget(name: "PamphletTool-focal-571",
                  path: "dist/PamphletTool-focal-571.zip"),
    .binaryTarget(name: "PamphletTool-fedora38-573",
                  path: "dist/PamphletTool-fedora38-573.zip"),
    .binaryTarget(name: "PamphletTool-focal-580",
                  path: "dist/PamphletTool-focal-580.zip"),
    .binaryTarget(name: "PamphletTool-focal-592",
                  path: "dist/PamphletTool-focal-592.zip"),
    .binaryTarget(name: "PamphletTool-jammy-592",
                  path: "dist/PamphletTool-jammy-592.zip"),
    .plugin(
        name: "PamphletPlugin",
        capability: .buildTool(),
        dependencies: plugins.map({ Target.Dependency(stringLiteral: $0) })
    ),
    .plugin(
        name: "PamphletReleaseOnlyPlugin",
        capability: .buildTool(),
        dependencies: plugins.map({ Target.Dependency(stringLiteral: $0) })
    ),
    .plugin(
        name: "PamphletGzipOnlyPlugin",
        capability: .buildTool(),
        dependencies: plugins.map({ Target.Dependency(stringLiteral: $0) })
    ),
]

#if os(Windows)
pluginTarget += [
    .binaryTarget(name: "PamphletTool-windows-592",
                  path: "dist/PamphletTool-windows-592.zip"),
]
#endif

#endif

let package = Package(
    name: "Pamphlet",
    products: productsTarget + [
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
    targets: pluginTarget + [
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
                .plugin(name: "PamphletPlugin")
            ]
        )
    ]
)
