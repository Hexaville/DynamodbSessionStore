import Foundation
import HexavilleFramework
import DynamoDB

enum DynamodbSessionStoreError: Error {
    case couldNotFindItem
}

public struct DynamodbSessionStore: SessionStoreProvider {
    
    let dynamodb: DynamoDB
    
    let tableName: String
    
    public init(tableName: String, dynamodb: DynamoDB) {
        self.dynamodb = dynamodb
        self.tableName = tableName
    }
    
    // TODO : implement here
    public func flush() throws {
        
    }
    
    public func read(forKey: String) throws -> [String : Any]? {
        let input = DynamoDB.GetItemInput(
            consistentRead: true,
            key: ["session_id": DynamoDB.AttributeValue(s: forKey)],
            tableName: tableName
        )
        
        let result: DynamoDB.GetItemOutput = try executeSync { done in
            do {
                try self.dynamodb.getItem(input).whenSuccess { response in
                    done(nil, response)
                }
            } catch {
                done(error, nil)
            }
        }
        
        guard let item = result.item?["value"], let jsonStr = item.s else {
            throw DynamodbSessionStoreError.couldNotFindItem
        }
        
        let encodedData = Data(bytes: Base64Encoder.shared.decode(Array(jsonStr.utf8)))
        return try JSONSerialization.jsonObject(with: encodedData, options: []) as? [String: Any]
    }
    
    public func write(value: [String : Any], forKey: String, ttl: Int?) throws {
        let data = try JSONSerialization.data(withJSONObject: value, options: [])
        let bytes = data.withUnsafeBytes({ [UInt8](UnsafeBufferPointer(start: $0, count: data.count)) })
        let stringValue = String(bytes: Base64Encoder.shared.encode(bytes), encoding: .utf8) ?? ""
        var item: [String: DynamoDB.AttributeValue] = [
            "session_id" : DynamoDB.AttributeValue(s: forKey),
            "value": DynamoDB.AttributeValue(s: stringValue)
        ]
        
        if let ttl = ttl {
            var date = Date()
            date.addTimeInterval(TimeInterval(ttl))
            item["expires_at"] = DynamoDB.AttributeValue(n: "\(Int(date.timeIntervalSince1970))")
        }
        
        let input = DynamoDB.PutItemInput(
            item: item,
            tableName: tableName
        )
        
        
        try executeSyncWithoutReturnValue { done in
            do {
                try self.dynamodb.putItem(input).whenSuccess { response in
                    done(nil)
                }
            } catch {
                done(error)
            }
        }
    }
    
    public func delete(forKey: String) throws {
        let input = DynamoDB.DeleteItemInput(
            key: ["session_id" : DynamoDB.AttributeValue(s: forKey)],
            tableName: tableName
        )
        
        try executeSyncWithoutReturnValue { done in
            do {
                try self.dynamodb.deleteItem(input).whenSuccess { response in
                    done(nil)
                }
            } catch {
                done(error)
            }
        }
    }
}


func executeSync<T>(_ fn: (@escaping (Error?, T?) -> Void) -> Void) throws -> T {
    let group = DispatchGroup()
    group.enter()
    
    var _error: Error?
    var _result: T?
    
    fn { error, result in
        if error != nil {
            _error = error
            return
        }
        
        _result = result
        
        group.leave()
    }
    
    group.wait()
    
    if let error = _error {
        throw error
    }
    
    return _result!
}


func executeSyncWithoutReturnValue(_ fn: (@escaping (Error?) -> Void) -> Void) throws {
    let group = DispatchGroup()
    group.enter()
    
    var _error: Error?
    
    fn { error in
        if error != nil {
            _error = error
            return
        }
        
        group.leave()
    }
    
    group.wait()
    
    if let error = _error {
        throw error
    }
}
