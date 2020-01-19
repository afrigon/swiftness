// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "swiftness",
    dependencies: [
		.package(url: "https://github.com/weichsel/ZIPFoundation/", .upToNextMajor(from: "0.9.10"))
    ],
    targets: [
        .target(
            name: "swiftness-ios",
            dependencies: ["ZIPFoundation"])
    ]
)

