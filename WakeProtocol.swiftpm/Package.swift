// swift-tools-version: 6.1
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "WakeProtocol",
    platforms: [
        .iOS("18.0")
    ],
    products: [
        .iOSApplication(
            name: "WakeProtocol",
            targets: ["AppModule"],
            bundleIdentifier: "com.student.wakeprotocol",
            displayVersion: "1.0",
            bundleVersion: "1",
            accentColor: .presetColor(.cyan),
            supportedDeviceFamilies: [.pad, .phone],
            supportedInterfaceOrientations: [.portrait]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "Sources",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
