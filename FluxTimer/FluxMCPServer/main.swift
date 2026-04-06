import Foundation

// Flux Timer MCP Server
// Communicates with Claude Code via stdin/stdout (JSON-RPC)
// Bridges to the Flux Timer app via Unix domain socket

let client = SocketClient()
let toolHandler = ToolHandler(client: client)
let resourceHandler = ResourceHandler(client: client)

func writeResponse(_ response: MCPResponse) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    guard let data = try? encoder.encode(response),
          var line = String(data: data, encoding: .utf8) else {
        return
    }
    line += "\n"
    FileHandle.standardOutput.write(line.data(using: .utf8)!)
}

func handleRequest(_ request: MCPRequest) {
    switch request.method {
    case "initialize":
        let result: [String: Any] = [
            "protocolVersion": "2024-11-05",
            "capabilities": [
                "tools": [String: Any](),
                "resources": [String: Any]()
            ],
            "serverInfo": [
                "name": "flux-timer",
                "version": "1.0.0"
            ]
        ]
        writeResponse(.result(id: request.id, value: result))

    case "notifications/initialized":
        // No response needed for notifications
        break

    case "tools/list":
        let result: [String: Any] = ["tools": mcpToolDefinitions]
        writeResponse(.result(id: request.id, value: result))

    case "tools/call":
        guard let toolName = request.params?.name else {
            writeResponse(.error(id: request.id, code: -32602, message: "Missing tool name"))
            return
        }
        let toolResult = toolHandler.handle(toolName: toolName, arguments: request.params?.arguments)
        let resultJSON: Any
        if let data = try? JSONSerialization.data(withJSONObject: toolResult),
           let text = String(data: data, encoding: .utf8) {
            resultJSON = [
                "content": [
                    ["type": "text", "text": text]
                ]
            ]
        } else {
            resultJSON = [
                "content": [
                    ["type": "text", "text": "{\"error\": \"Failed to serialize result\"}"]
                ]
            ]
        }
        writeResponse(.result(id: request.id, value: resultJSON))

    case "resources/list":
        let result: [String: Any] = ["resources": mcpResourceDefinitions]
        writeResponse(.result(id: request.id, value: result))

    case "resources/read":
        guard let uri = request.params?.uri else {
            writeResponse(.error(id: request.id, code: -32602, message: "Missing resource URI"))
            return
        }
        let resourceResult = resourceHandler.handle(uri: uri)
        writeResponse(.result(id: request.id, value: resourceResult))

    default:
        writeResponse(.error(id: request.id, code: -32601, message: "Method not found: \(request.method)"))
    }
}

// Main stdio loop
let decoder = JSONDecoder()
var inputBuffer = Data()

while let line = readLine(strippingNewline: true) {
    guard !line.isEmpty else { continue }
    guard let data = line.data(using: .utf8) else { continue }

    do {
        let request = try decoder.decode(MCPRequest.self, from: data)
        handleRequest(request)
    } catch {
        let errorResponse = MCPResponse.error(
            id: nil,
            code: -32700,
            message: "Parse error: \(error.localizedDescription)"
        )
        writeResponse(errorResponse)
    }
}
