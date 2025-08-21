// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TideWidget",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "TideWidget",
            targets: ["TideWidget"]
        )
    ],
    targets: [
        .executableTarget(
            name: "TideWidget",
            dependencies: [],
            path: "Sources/TideWidgetExtension",
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ]
        )
    ]
)