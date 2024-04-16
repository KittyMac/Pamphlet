// swift-tools-version:5.6
import PackageDescription

// When runnning "make release" to build the binary tools change this to true
// Otherwise always set it to false
#if false
let productsTarget: [PackageDescription.Product] = [
    
]
let pluginTarget: [PackageDescription.Target] = [
    .executableTarget(
        name: "PamphletTool-focal",
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
            "PamphletTool-focal",
        ]
    ),
    .plugin(
        name: "PamphletReleaseOnlyPlugin",
        capability: .buildTool(),
        dependencies: [
            "PamphletTool-focal",
        ]
    ),
    .plugin(
        name: "PamphletGzipOnlyPlugin",
        capability: .buildTool(),
        dependencies: [
            "PamphletTool-focal",
        ]
    ),
]
#else

var plugins = [
    "PamphletTool-focal",
    "PamphletTool-amazonlinux2",
    "PamphletTool-fedora",
    "PamphletTool-fedora38",
]

#if os(Windows)
plugins += [
    "PamphletTool-windows",
]
#endif

var productsTarget: [PackageDescription.Product] = [
    .library(name: "PamphletTool", targets: plugins),
]
var pluginTarget: [PackageDescription.Target] = [
    .binaryTarget(name: "PamphletTool-focal",
                  path: "dist/PamphletTool-focal.zip"),
    .binaryTarget(name: "PamphletTool-amazonlinux2",
                  path: "dist/PamphletTool-amazonlinux2.zip"),
    .binaryTarget(name: "PamphletTool-fedora",
                  path: "dist/PamphletTool-fedora.zip"),
    .binaryTarget(name: "PamphletTool-fedora38",
                  path: "dist/PamphletTool-fedora38.zip"),
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
    .binaryTarget(name: "PamphletTool-windows",
                  path: "dist/PamphletTool-windows.zip"),
]
#endif

#endif

let package = Package(
    name: "Pamphlet",
    platforms: [
        .macOS(.v10_13), .iOS(.v11)
    ],
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
                .plugin(name: "PamphletGzipOnlyPlugin")
            ]
        )
    ]
)
