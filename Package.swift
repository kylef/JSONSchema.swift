// swift-tools-version:4.2

import PackageDescription

let package = Package(
  name: "JSONSchema",
  products: [
    .library(name: "JSONSchema", targets: ["JSONSchema"]),
  ],
  dependencies: [
    .package(url: "https://github.com/kylef/PathKit.git", .upToNextMajor(from: "1.0.0")),
  ],
  targets: [
    .target(name: "JSONSchema", dependencies: [], path: "Sources"),
    .testTarget(name: "JSONSchemaTests", dependencies: ["JSONSchema", "PathKit"]),
  ]
)
