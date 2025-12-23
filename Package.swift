// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VolvoCarsAPI",
    platforms: [.iOS(.v16), .macOS(.v13), .watchOS(.v9), .tvOS(.v16)],
    products: [
        .executable(name: "VolvoCarsAPICLT", targets: ["VolvoCarsAPICLT"]),
        .library(name: "VolvoCarsAPI", targets: ["VolvoCarsAPI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.2"),
    ],
    targets: [
        .target(
            name: "VolvoCarsAPI",
            dependencies: []
        ),
        .executableTarget(
            name: "VolvoCarsAPICLT",
            dependencies: [
                .target(name: "VolvoCarsAPI", condition: .when(platforms: [.macOS])),
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser",
                    condition: .when(platforms: [.macOS])
                ),
            ]
        ),
        .testTarget(
            name: "VolvoCarsAPITests",
            dependencies: ["VolvoCarsAPI"]
        ),
    ]
)
