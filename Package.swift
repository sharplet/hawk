// swift-tools-version:4.2

import PackageDescription

let package = Package(
  name: "observer",
  targets: [
    .target(name: "observer"),
    .testTarget(name: "ObserverTests", dependencies: ["observer"]),
  ]
)
