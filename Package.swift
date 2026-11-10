// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DesignTokens",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "DesignTokens",
            targets: ["DesignTokens"]
        ),
        // Apple platforms only in practice: the target is empty where SwiftUI cannot be imported, so the core
        // product above stays Foundation-only.
        .library(
            name: "DesignTokensSwiftUI",
            targets: ["DesignTokensSwiftUI"]
        ),
        .executable(
            name: "design-tokens",
            targets: ["design-tokens"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin.git", from: "1.4.3"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "DesignTokens",
            resources: [
                // This toolchain does not classify .docc catalogues on its own.
                .copy("DesignTokens.docc")
            ],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
        .target(
            name: "DesignTokensSwiftUI",
            dependencies: ["DesignTokens"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
        .executableTarget(
            name: "design-tokens",
            dependencies: ["DesignTokens"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
        // Renders every Swiss component, light and dark, to PNGs and an index.html: `swift run swiss-gallery <folder>`.
        // Empty where AppKit is unavailable, so the package still builds on Linux.
        .executableTarget(
            name: "swiss-gallery",
            dependencies: ["DesignTokens", "DesignTokensSwiftUI"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
        .testTarget(
            name: "DesignTokensTests",
            dependencies: ["DesignTokens"],
            // A note, not a resource: see Vendored/README.md.
            exclude: ["Vendored"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
        .testTarget(
            name: "DesignTokensSwiftUITests",
            dependencies: ["DesignTokensSwiftUI", "DesignTokens"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
    ]
)
