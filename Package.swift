// swift-tools-version:5.0

import PackageDescription

let package = Package(
  name: "JSONSchema",
  platforms: [
    .macOS(.v10_13), .iOS(.v11), .tvOS(.v11)
  ],
  products: [
    .library(name: "JSONSchema", targets: ["JSONSchema"]),
  ],
  dependencies: [
    .package(url: "https://github.com/kylef/PathKit.git", .upToNextMajor(from: "1.0.0")),
    .package(url: "https://github.com/kylef/Spectre.git", .revision("d02129a9af77729de049d328dd61e530b6f2bb2b"))
  ],
  targets: [
    .target(name: "JSONSchema", dependencies: [], path: "Sources"),
    .testTarget(name: "JSONSchemaTests", dependencies: ["JSONSchema", "Spectre", "PathKit"]),
  ]
)
