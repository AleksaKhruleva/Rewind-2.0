// swift-tools-version: 6.0
@preconcurrency import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        // Customize the product types for specific package product
        // Default is .staticFramework
        // productTypes: ["Alamofire": .framework,]
        productTypes: [:]
    )
#endif

let package = Package(
    name: "Rewind",
    dependencies: [
        .package(url: "https://github.com/Moya/Moya", .upToNextMajor(from: "15.0.0")),
        .package(url: "https://github.com/realm/SwiftLint", .upToNextMajor(from: "0.59.1")),
        .package(url: "https://github.com/vapor/vapor.git", .upToNextMajor(from: "4.114.0")),
    ]
)
