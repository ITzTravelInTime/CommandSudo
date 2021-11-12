// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CommandSudo",
    platforms: [
        .macOS("10.9")
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "CommandSudo",
            targets: ["CommandSudo"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/ITzTravelInTime/Command", from: "2.1.2"),
        .package(url: "https://github.com/ITzTravelInTime/TINURecovery", from: "4.0.0"),
        .package(url: "https://github.com/ITzTravelInTime/TINUNotifications", from: "3.0.7"),
        .package(url: "https://github.com/ITzTravelInTime/SwiftLoggedPrint", from: "3.1.2")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "CommandSudo",
            dependencies: [
                .byName(name: "Command"),
                .byName(name: "TINURecovery"),
                .byName(name: "TINUNotifications"),
                .byName(name: "SwiftLoggedPrint")
            ]),
        .testTarget(
            name: "CommandSudoTests",
            dependencies: ["CommandSudo"]),
    ]
)
