// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "Imperial",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .library(name: "ImperialCore", targets: ["ImperialCore"]),
        .library(name: "Imperial4shared", targets: ["ImperialCore", "Imperial4shared"]),
        .library(name: "ImperialBox", targets: ["ImperialCore", "ImperialBox"]),
        .library(name: "ImperialDeviantArt", targets: ["ImperialCore", "ImperialDeviantArt"]),
        .library(name: "ImperialDropbox", targets: ["ImperialCore", "ImperialDropbox"]),
        .library(name: "ImperialFacebook", targets: ["ImperialCore", "ImperialFacebook"]),
        .library(name: "ImperialGitHub", targets: ["ImperialCore", "ImperialGitHub"]),
        .library(name: "ImperialGitlab", targets: ["ImperialCore", "ImperialGitlab"]),
        .library(name: "ImperialGoogle", targets: ["ImperialCore", "ImperialGoogle"]),
        .library(name: "ImperialImgur", targets: ["ImperialCore", "ImperialImgur"]),
        .library(name: "ImperialKeycloak", targets: ["ImperialCore", "ImperialKeycloak"]),
        .library(name: "ImperialMixcloud", targets: ["ImperialCore", "ImperialMixcloud"]),
        .library(name: "ImperialShopify", targets: ["ImperialCore", "ImperialShopify"]),
        .library(name: "Imperial", targets: [
            "ImperialCore",
            "Imperial4shared",
            "ImperialBox",
            "ImperialDeviantArt",
            "ImperialDropbox",
            "ImperialFacebook",
            "ImperialGitHub",
            "ImperialGitlab",
            "ImperialGoogle",
            "ImperialImgur",
            "ImperialKeycloak",
            "ImperialMixcloud",
            "ImperialShopify"
        ]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0-rc.3.5"),
        .package(url: "https://github.com/vapor/jwt-kit.git", from: "4.0.0-rc")
    ],
    targets: [
        .target(
            name: "ImperialCore",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "JWTKit", package: "jwt-kit"),
            ]
        ),
        .target(name: "Imperial4shared", dependencies: ["ImperialCore"]),
        .target(name: "ImperialBox", dependencies: ["ImperialCore"]),
        .target(name: "ImperialDeviantArt", dependencies: ["ImperialCore"]),
        .target(name: "ImperialDropbox", dependencies: ["ImperialCore"]),
        .target(name: "ImperialFacebook", dependencies: ["ImperialCore"]),
        .target(name: "ImperialGitHub", dependencies: ["ImperialCore"]),
        .target(name: "ImperialGitlab", dependencies: ["ImperialCore"]),
        .target(name: "ImperialGoogle", dependencies: ["ImperialCore"]),
        .target(name: "ImperialImgur", dependencies: ["ImperialCore"]),
        .target(name: "ImperialKeycloak", dependencies: ["ImperialCore"]),
        .target(name: "ImperialMixcloud", dependencies: ["ImperialCore"]),
        .target(name: "ImperialShopify", dependencies: ["ImperialCore"]),
        .testTarget(name: "ImperialTests", dependencies: ["ImperialCore", "ImperialShopify"]),
    ]
)
