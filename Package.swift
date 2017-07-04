// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "DynamodbSessionStore",
    targets: [
        Target(name: "DynamodbSessionStore"),
        Target(name: "DynamodbSessionStoreTableManager"),
        Target(name: "DynamodbSessionStoreExample", dependencies: ["DynamodbSessionStore"])
    ],
    dependencies: [
        .Package(url: "https://github.com/swift-aws/dynamodb.git", majorVersion: 0, minor: 1),
        .Package(url: "https://github.com/noppoMan/HexavilleFramework.git", majorVersion: 0, minor: 1)
    ]
)
