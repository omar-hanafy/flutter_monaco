// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "flutter_monaco",
  platforms: [
    .macOS("12.0")
  ],
  products: [
    .library(name: "flutter-monaco", targets: ["flutter_monaco"])
  ],
  dependencies: [
    .package(name: "FlutterFramework", path: "../FlutterFramework")
  ],
  targets: [
    .target(
      name: "flutter_monaco",
      dependencies: [
        .product(name: "FlutterFramework", package: "FlutterFramework")
      ]
    )
  ]
)
