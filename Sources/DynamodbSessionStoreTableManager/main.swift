import Foundation
import SwiftAWSDynamodb
import Prorsum
import SwiftCLI

class CreateCommand: Command {
    
    enum CreateCommandError: Error {
        case timeout
    }
    
    let name = "create"
    let tableName = Parameter()
    let writeCapacityUnits = Key<Int>("--writeCapacityUnits", usage: "numnber of WriteCapacityUnits")
    let readCapacityUnits = Key<Int>("--readCapacityUnits", usage: "numnber of ReadCapacityUnits")
    let endpoint = Key<String>("--endpoint", usage: "The endpoint string. ex: http://localhost:8000")
    
    func execute() throws {
        let dynamodb = Dynamodb(endpoint: endpoint.value)
        let input = Dynamodb.CreateTableInput(
            attributeDefinitions: [
                Dynamodb.AttributeDefinition(attributeType: .s, attributeName: "session_id"),
            ],
            keySchema: [
                Dynamodb.KeySchemaElement(attributeName: "session_id", keyType: .hash)
            ],
            provisionedThroughput: Dynamodb.ProvisionedThroughput(
                writeCapacityUnits: Int64(writeCapacityUnits.value ?? 10),
                readCapacityUnits: Int64(readCapacityUnits.value ?? 10)
            ),
            tableName: tableName.value
        )
        
        do {
            _ = try dynamodb.createTable(input)
            let timeToLiveSpecificationInput = Dynamodb.TimeToLiveSpecification(
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
                
                let describeTableOutput = try dynamodb.describeTable(Dynamodb.DescribeTableInput(tableName: tableName.value))
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
            
            let updateTimeToLiveInput = Dynamodb.UpdateTimeToLiveInput(
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
    let endpoint = Key<String>("--endpoint", usage: "The endpoint string. ex: http://localhost:8000")
    
    func execute() throws {
        do {
            let dynamodb = Dynamodb(endpoint: endpoint.value)
            _ = try dynamodb.deleteTable(Dynamodb.DeleteTableInput(tableName: tableName.value))
        } catch {
            print(error)
            throw error
        }
    }
}

CLI.setup(name: "hexaville-dynamodb-session-store-table-manager")
CLI.register(commands: [CreateCommand(), DeleteCommand()])
_ = CLI.go()
