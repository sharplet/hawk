// swift-tools-version:4.2

import PackageDescription

let package = Package(
  name: "hawk",
  targets: [
    .target(name: "hawk", dependencies: ["Files"]),
    .target(name: "Files", dependencies: ["Clibc"]),
    .target(name: "Clibc"),
    .testTarget(name: "HawkTests", dependencies: ["hawk"]),
  ]
)
