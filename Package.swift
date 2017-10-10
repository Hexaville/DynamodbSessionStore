// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "DynamodbSessionStore",
    products: [
        .library(name: "DynamodbSessionStore", targets: ["DynamodbSessionStore"]),
        .executable(name: "dynamodb-session-store-table-manager", targets: ["DynamodbSessionStoreTableManager"]),
        .executable(name: "dynamodb-session-store-example", targets: ["DynamodbSessionStoreExample"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-aws/dynamodb.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/noppoMan/HexavilleFramework.git", .upToNextMajor(from: "0.1.15"))
    ],
    targets: [
        .target(name: "DynamodbSessionStore", dependencies: ["SwiftAWSDynamodb", "HexavilleFramework"]),
        .target(name: "DynamodbSessionStoreTableManager", dependencies: ["DynamodbSessionStore"]),
        .target(name: "DynamodbSessionStoreExample", dependencies: ["DynamodbSessionStore"])
    ]
)
