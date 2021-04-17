// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DeepLook",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "DeepLook",
            targets: ["DeepLook"]),
    ],
    dependencies: [
        .package(url: "https://github.com/LA-Labs/LADSA.git",  .upToNextMajor(from: "0.0.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "DeepLook",
            dependencies: [.target(name: "DeepLookModels", condition: .when(platforms: [.iOS])), "LADSA"]),
        .binaryTarget(name: "DeepLookModels", path: "./Sources/DeepLookModels.xcframework"),
        .testTarget(
            name: "DeepLookTests",
            dependencies: ["DeepLook"]),
    ]
)
