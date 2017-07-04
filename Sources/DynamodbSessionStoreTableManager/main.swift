import Foundation
import SwiftAWSDynamodb
import Prorsum
import SwiftCLI

class CreateCommand: Command {
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
            let output = try dynamodb.createTable(input)
            if let desc = output.tableDescription {
                print(desc)
            }
            print("Successfully created \(tableName.value) .")
        } catch {
            print(error)
            throw error
        }
    }
}

CLI.setup(name: "hexaville-dynamodb-session-store-table-manager")
CLI.register(commands: [CreateCommand()])
_ = CLI.go()
