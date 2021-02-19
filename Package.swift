// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "ClipSDK",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "ClipSDK",
            // TODO: consider commenting `type: .dynamic` before public release. it's here to use Xcode Previews in Sample app, to work around an Xcode bug.
//            type: .dynamic,
            targets: ["ClipSDK", "ClipModel"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/WeTransfer/Mocker", .revision("8ff37ffda243669ba7827f639f91f99b53fa4b49"))
    ],
    targets: [
        .target(
            name: "ClipSDK",
            dependencies: ["ClipModel"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "ClipModel"
        ),
        .testTarget(
            name: "ClipServiceTests",
            dependencies: ["ClipSDK", "Mocker"]
        )
    ]
)
