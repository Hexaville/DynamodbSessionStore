# DynamodbSessionStore
Dynamodb Session Store for Hexaville

## Installation

Just add this repository url to your `Package.swift`

### Package.swift
```swift
// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "MyHexavilleApp",
    dependencies: [
        .Package(url: "https://github.com/Hexaville/DynamodbSessionStore.git", majorVersion: 0, minor: 1)
    ]
)
```

### Pre create the table for session data storeing from CLI

If you didn't create the table before, You need to create it first.
The instruction is following.

#### Build and execute DynamodbSessionStoreTableManager
```
cd /path/to/YourApp
swift build
./.build/debug/DynamodbSessionStoreTableManager
```

### The output is ....
```
Available commands: 
- create              
- delete              
- help                Prints this help information
- version             Prints the current version of this app
```

### Create Table for session storeing
```
./.build/debug/DynamodbSessionStoreTableManager create table_name
```

## Usage

You can specify following credential information in environment variables.

* AWS_DEFAULT_REGION
* AWS_ACCESS_KEY_ID
* AWS_SECRET_ACCESS_KEY


```swift
import Foundation
import HexavilleFramework
import DynamodbSessionStore
import SwiftAWSDynamodb

let app = HexavilleFramework()

let session = SessionMiddleware(
    cookieAttribute: CookieAttribute(expiration: 3600, httpOnly: true, secure: false),
    store: DynamodbSessionStore(
        tableName: "my-app-session",
        dynamodb: Dynamodb()
    )
)

app.use(session)

app.use { req, context in
    context.session?["now"] = "\(Date())"
    return .next(req)
}

let router = Router()

router.use(.get, "/") { req, context in
    if let now = context.session?["now"] {
        return Response(body: "current time is: \(now)")
    } else {
        return Response(body: "No session")
    }
}

app.use(router)

try app.run()
```
