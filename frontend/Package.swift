// swift-tools-version: 6.0

import PackageDescription

let package = Package(
	name: "Doggo",
	platforms: [
		.iOS(.v17),
		.macOS(.v14)
	],
	products: [
		.library(name: "Doggo", targets: ["Doggo"])
	],
	targets: [
		.target(
			name: "Doggo",
			path: "Sources/Doggo",
			resources: [
				.process("Resources")
			]
		)
	]
)
