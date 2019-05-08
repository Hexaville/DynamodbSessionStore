import Foundation
import DynamoDB
import SwiftCLI

class CreateCommand: Command {
    
    enum CreateCommandError: Error {
        case timeout
    }
    
    let name = "create"
    let tableName = Parameter()
    let writeCapacityUnits = Key<Int>("--writeCapacityUnits", description: "numnber of WriteCapacityUnits")
    let readCapacityUnits = Key<Int>("--readCapacityUnits", description: "numnber of ReadCapacityUnits")
    let endpoint = Key<String>("--endpoint", description: "The endpoint string. ex: http://localhost:8000")
    
    func execute() throws {
        let dynamodb = DynamoDB(endpoint: endpoint.value)
        let input = DynamoDB.CreateTableInput(
            attributeDefinitions: [
                DynamoDB.AttributeDefinition(attributeName: "session_id", attributeType: .s),
            ],
            keySchema: [
                DynamoDB.KeySchemaElement(attributeName: "session_id", keyType: .hash)
            ],
            provisionedThroughput: DynamoDB.ProvisionedThroughput(
                readCapacityUnits: Int64(readCapacityUnits.value ?? 10),
                writeCapacityUnits: Int64(writeCapacityUnits.value ?? 10)
            ),
            tableName: tableName.value
        )
        
        do {
            _ = try dynamodb.createTable(input)
            let timeToLiveSpecificationInput = DynamoDB.TimeToLiveSpecification(
                attributeName: "expires_at",
                enabled: true
            )
            
            print("Sent createTable request for \(tableName.value)")
            
            let cond = Cond()
            
            var tableStatusIsActive = false
            let timeout = Date().addingTimeInterval(60).timeIntervalSince1970
            let now = Date().timeIntervalSince1970
            var isFirst = true
            
            while !tableStatusIsActive {
                if isFirst {
                    print("waiting \(tableName.value) become active...")
                    isFirst = false
                }
                
                if now > timeout {
                    throw CreateCommandError.timeout
                }
                
                let describeTableOutput = try dynamodb.describeTable(DynamoDB.DescribeTableInput(tableName: tableName.value))
                guard let tableStatus = describeTableOutput.table?.tableStatus else {
                    fatalError("TableStatus must not empty")
                }
                
                switch tableStatus {
                case .active:
                    tableStatusIsActive = true
                default:
                    break
                }
                
                cond.wait(timeout: 1)
            }
            
            print("\(tableName.value) became active.")
            
            print("Applying updateTimeToLive configuration to \(tableName.value)....")
            
            let updateTimeToLiveInput = DynamoDB.UpdateTimeToLiveInput(
                tableName: tableName.value,
                timeToLiveSpecification: timeToLiveSpecificationInput
            )
            
            _ = try dynamodb.updateTimeToLive(updateTimeToLiveInput)
            
            print("Successfully created \(tableName.value) .")
        } catch {
            print(error)
            throw error
        }
    }
}

class DeleteCommand: Command {
    let name = "delete"
    let tableName = Parameter()
    let endpoint = Key<String>("--endpoint", description: "The endpoint string. ex: http://localhost:8000")
    
    func execute() throws {
        do {
            let dynamodb = DynamoDB(endpoint: endpoint.value)
            _ = try dynamodb.deleteTable(DynamoDB.DeleteTableInput(tableName: tableName.value))
        } catch {
            print(error)
            throw error
        }
    }
}

let ddbSesTableManagerCLI = CLI(name: "hexaville-dynamodb-session-store-table-manager")
ddbSesTableManagerCLI.commands = [CreateCommand(), DeleteCommand()]
_ = ddbSesTableManagerCLI.go()
