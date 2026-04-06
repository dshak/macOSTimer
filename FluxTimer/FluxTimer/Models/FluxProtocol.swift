import Foundation

// Shared protocol types for communication between Flux Timer app and MCP server
// via Unix domain socket at /tmp/flux-timer.sock

struct FluxRequest: Codable {
    let id: String
    let action: String
    let timerId: String?
    let params: [String: String]?
}

struct FluxResponse: Codable {
    let id: String
    let success: Bool
    let data: String?  // JSON-encoded payload
    let error: String?

    static func ok(id: String, data: Any) -> FluxResponse {
        let jsonData = try? JSONSerialization.data(withJSONObject: data, options: [.sortedKeys])
        let jsonString = jsonData.flatMap { String(data: $0, encoding: .utf8) }
        return FluxResponse(id: id, success: true, data: jsonString, error: nil)
    }

    static func fail(id: String, error: String) -> FluxResponse {
        FluxResponse(id: id, success: false, data: nil, error: error)
    }
}

enum FluxAction: String {
    case create
    case start
    case pause
    case reset
    case stop
    case get
    case list
    case update
    case history
    case settings
}

let fluxSocketPath = "/tmp/flux-timer.sock"
