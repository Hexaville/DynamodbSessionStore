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
        
        let group = DispatchGroup()
        group.enter()
        
        var _result: DynamoDB.GetItemOutput?
        var _error: Error?
        
        DispatchQueue.global().async {
            do {
                _result = try self.dynamodb.getItem(input)
            } catch {
                _error = error
            }
            group.leave()
        }
    
        group.wait()
        
        if let error = _error {
            throw error
        }
        
        guard let item = _result?.item?["value"], let jsonStr = item.s else {
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
        
        print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        print(item)
        
        if let ttl = ttl {
            var date = Date()
            date.addTimeInterval(TimeInterval(ttl))
            item["expires_at"] = DynamoDB.AttributeValue(n: "\(Int(date.timeIntervalSince1970))")
        }
        
        let input = DynamoDB.PutItemInput(
            item: item,
            tableName: tableName
        )
        
        let group = DispatchGroup()
        group.enter()
        
        var _error: Error?
        
        DispatchQueue.global().async {
            do {
                _ = try self.dynamodb.putItem(input)
            } catch {
                _error = error
            }
            group.leave()
        }
        
        group.wait()
        
        if let error = _error {
            throw error
        }
    }
    
    public func delete(forKey: String) throws {
        let input = DynamoDB.DeleteItemInput(
            key: ["session_id" : DynamoDB.AttributeValue(s: forKey)],
            tableName: tableName
        )
        
        let group = DispatchGroup()
        group.enter()
        
        var _error: Error?
        
        DispatchQueue.global().async {
            do {
                _ = try self.dynamodb.deleteItem(input)
            } catch {
                _error = error
            }
            group.leave()
        }
        
        group.wait()
        
        if let error = _error {
            throw error
        }
    }
    
}

