// swift-tools-version:4.2

import PackageDescription

let package = Package(
  name: "observer",
  targets: [
    .target(name: "observer", dependencies: ["Files"]),
    .target(name: "Files", dependencies: ["Clibc"]),
    .target(name: "Clibc"),
    .testTarget(name: "ObserverTests", dependencies: ["observer"]),
  ]
)
