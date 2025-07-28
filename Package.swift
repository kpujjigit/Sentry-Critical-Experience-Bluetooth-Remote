// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BluetoothRemote",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "BluetoothRemote",
            targets: ["BluetoothRemote"]),
    ],
    dependencies: [
        .package(url: "https://github.com/getsentry/sentry-cocoa.git", from: "8.53.2")
    ],
    targets: [
        .target(
            name: "BluetoothRemote",
            dependencies: [
                .product(name: "Sentry", package: "sentry-cocoa")
            ]),
        .testTarget(
            name: "BluetoothRemoteTests",
            dependencies: ["BluetoothRemote"]),
    ]
) 