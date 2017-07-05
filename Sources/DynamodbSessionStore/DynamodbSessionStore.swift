import Foundation
import HexavilleFramework
import SwiftAWSDynamodb

enum DynamodbSessionStoreError: Error {
    case couldNotFindItem
}

public struct DynamodbSessionStore: SessionStoreProvider {
    
    let dynamodb: Dynamodb
    
    let tableName: String
    
    public init(tableName: String, dynamodb: Dynamodb) {
        self.dynamodb = dynamodb
        self.tableName = tableName
    }
    
    // TODO : implement here
    public func flush() throws {
        
    }
    
    public func read(forKey: String) throws -> [String : Any]? {
        let input = Dynamodb.GetItemInput(
            consistentRead: true,
            key: ["session_id": Dynamodb.AttributeValue(s: forKey)],
            tableName: tableName
        )
        let result = try dynamodb.getItem(input)
        guard let item = result.item?["value"], let jsonStr = item.s else {
            throw DynamodbSessionStoreError.couldNotFindItem
        }
        
        let encodedData = Data(bytes: Base64Encoder.shared.decode(Array(jsonStr.utf8)))
        return try JSONSerialization.jsonObject(with: encodedData, options: []) as? [String: Any]
    }
    
    public func write(value: [String : Any], forKey: String, ttl: Int?) throws {
        let data = try JSONSerialization.data(withJSONObject: value, options: [])
        let stringValue = String(bytes: Base64Encoder.shared.encode(data.bytes), encoding: .utf8) ?? ""
        var item: [String: Dynamodb.AttributeValue] = [
            "session_id" : Dynamodb.AttributeValue(s: forKey),
            "value": Dynamodb.AttributeValue(s: stringValue)
        ]
        
        if let ttl = ttl {
            var date = Date()
            date.addTimeInterval(TimeInterval(ttl))
            item["expires_at"] = Dynamodb.AttributeValue(n: "\(Int(date.timeIntervalSince1970))")
        }
        
        let input = Dynamodb.PutItemInput(
            item: item,
            tableName: tableName
        )
        
        _ = try dynamodb.putItem(input)
    }
    
    public func delete(forKey: String) throws {
        let input = Dynamodb.DeleteItemInput(
            key: ["session_id" : Dynamodb.AttributeValue(s: forKey)],
            tableName: tableName
        )
        _ = try dynamodb.deleteItem(input)
    }
    
}
