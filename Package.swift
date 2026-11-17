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
        // The one place this package starts a child process (`posix_spawn`, for the headless-Chrome blog fetch). tvOS and
        // watchOS mark those calls unavailable, so they live here, outside the core, and the sources are empty where the
        // calls do not exist: `DesignTokens` and `DesignTokensSwiftUI` build for every platform without them. Not a product.
        .target(
            name: "DesignTokensChrome",
            dependencies: ["DesignTokens"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
        .executableTarget(
            name: "design-tokens",
            dependencies: ["DesignTokens", "DesignTokensChrome"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
        // The scenes the gallery draws, shared by the macOS gallery executable and the iOS Simulator render test. Not a product.
        .target(
            name: "SwissGalleryScenes",
            dependencies: ["DesignTokens", "DesignTokensSwiftUI"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
        // Renders every Swiss component, light and dark, to PNGs and an index.html: `swift run swiss-gallery <folder>`.
        // Empty where AppKit is unavailable, so the package still builds on Linux.
        .executableTarget(
            name: "swiss-gallery",
            dependencies: ["DesignTokens", "DesignTokensSwiftUI", "SwissGalleryScenes"],
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
            name: "DesignTokensChromeTests",
            dependencies: ["DesignTokensChrome", "DesignTokens"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
        .testTarget(
            name: "DesignTokensSwiftUITests",
            dependencies: ["DesignTokensSwiftUI", "DesignTokens", "SwissGalleryScenes"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
    ]
)
