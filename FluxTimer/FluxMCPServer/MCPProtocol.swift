import Foundation

// MCP JSON-RPC Protocol Types

struct MCPRequest: Codable {
    let jsonrpc: String
    let id: AnyCodableValue?
    let method: String
    let params: MCPParams?
}

struct MCPParams: Codable {
    let name: String?
    let arguments: [String: AnyCodableValue]?
    let uri: String?
}

struct MCPResponse: Codable {
    let jsonrpc: String
    let id: AnyCodableValue?
    let result: AnyCodableValue?
    let error: MCPError?

    static func result(id: AnyCodableValue?, value: Any) -> MCPResponse {
        MCPResponse(
            jsonrpc: "2.0",
            id: id,
            result: AnyCodableValue(value),
            error: nil
        )
    }

    static func error(id: AnyCodableValue?, code: Int, message: String) -> MCPResponse {
        MCPResponse(
            jsonrpc: "2.0",
            id: id,
            result: nil,
            error: MCPError(code: code, message: message)
        )
    }
}

struct MCPError: Codable {
    let code: Int
    let message: String
}

// A flexible JSON value type for MCP communication
enum AnyCodableValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null
    case array([AnyCodableValue])
    case object([String: AnyCodableValue])

    init(_ value: Any) {
        switch value {
        case let s as String: self = .string(s)
        case let i as Int: self = .int(i)
        case let d as Double: self = .double(d)
        case let b as Bool: self = .bool(b)
        case let a as [Any]: self = .array(a.map { AnyCodableValue($0) })
        case let d as [String: Any]: self = .object(d.mapValues { AnyCodableValue($0) })
        default: self = .null
        }
    }

    var stringValue: String? {
        if case .string(let s) = self { return s }
        return nil
    }

    var intValue: Int? {
        if case .int(let i) = self { return i }
        if case .double(let d) = self { return Int(d) }
        return nil
    }

    var doubleValue: Double? {
        if case .double(let d) = self { return d }
        if case .int(let i) = self { return Double(i) }
        return nil
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let b = try? container.decode(Bool.self) {
            self = .bool(b)
        } else if let i = try? container.decode(Int.self) {
            self = .int(i)
        } else if let d = try? container.decode(Double.self) {
            self = .double(d)
        } else if let s = try? container.decode(String.self) {
            self = .string(s)
        } else if let a = try? container.decode([AnyCodableValue].self) {
            self = .array(a)
        } else if let o = try? container.decode([String: AnyCodableValue].self) {
            self = .object(o)
        } else {
            self = .null
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .int(let i): try container.encode(i)
        case .double(let d): try container.encode(d)
        case .bool(let b): try container.encode(b)
        case .null: try container.encodeNil()
        case .array(let a): try container.encode(a)
        case .object(let o): try container.encode(o)
        }
    }
}

// Tool definitions for MCP
let mcpToolDefinitions: [[String: Any]] = [
    [
        "name": "flux_create_timer",
        "description": "Create a new timer window. Does not auto-start — call flux_start_timer to begin.",
        "inputSchema": [
            "type": "object",
            "properties": [
                "mode": ["type": "string", "enum": ["countdown", "countup"], "description": "Timer mode"],
                "duration": ["type": "number", "description": "Duration in seconds (required for countdown)"],
                "label": ["type": "string", "description": "Optional label for the timer"]
            ],
            "required": ["mode"]
        ]
    ],
    [
        "name": "flux_start_timer",
        "description": "Start or resume a timer.",
        "inputSchema": [
            "type": "object",
            "properties": [
                "timer_id": ["type": "string", "description": "The timer ID to start"]
            ],
            "required": ["timer_id"]
        ]
    ],
    [
        "name": "flux_pause_timer",
        "description": "Pause a running timer.",
        "inputSchema": [
            "type": "object",
            "properties": [
                "timer_id": ["type": "string", "description": "The timer ID to pause"]
            ],
            "required": ["timer_id"]
        ]
    ],
    [
        "name": "flux_reset_timer",
        "description": "Reset a timer to its initial state.",
        "inputSchema": [
            "type": "object",
            "properties": [
                "timer_id": ["type": "string", "description": "The timer ID to reset"]
            ],
            "required": ["timer_id"]
        ]
    ],
    [
        "name": "flux_stop_timer",
        "description": "Stop and close a timer window. Logs the session to history.",
        "inputSchema": [
            "type": "object",
            "properties": [
                "timer_id": ["type": "string", "description": "The timer ID to stop"]
            ],
            "required": ["timer_id"]
        ]
    ],
    [
        "name": "flux_get_timer",
        "description": "Get the current state of a specific timer including elapsed time, remaining time, and label.",
        "inputSchema": [
            "type": "object",
            "properties": [
                "timer_id": ["type": "string", "description": "The timer ID to query"]
            ],
            "required": ["timer_id"]
        ]
    ],
    [
        "name": "flux_list_timers",
        "description": "List all active timers with their current states.",
        "inputSchema": [
            "type": "object",
            "properties": [:]
        ]
    ],
    [
        "name": "flux_update_timer",
        "description": "Update a timer's label or alert settings while it's running.",
        "inputSchema": [
            "type": "object",
            "properties": [
                "timer_id": ["type": "string", "description": "The timer ID to update"],
                "label": ["type": "string", "description": "New label for the timer"],
                "sound": ["type": "boolean", "description": "Enable/disable sound alert"],
                "notification": ["type": "boolean", "description": "Enable/disable notification alert"],
                "flash": ["type": "boolean", "description": "Enable/disable flash alert"]
            ],
            "required": ["timer_id"]
        ]
    ]
]

let mcpResourceDefinitions: [[String: Any]] = [
    [
        "uri": "flux://history",
        "name": "Session History",
        "description": "Completed timer session log with labels, durations, and timestamps",
        "mimeType": "application/json"
    ],
    [
        "uri": "flux://timers",
        "name": "Active Timers",
        "description": "Live list of all active timers with full state",
        "mimeType": "application/json"
    ],
    [
        "uri": "flux://settings",
        "name": "App Settings",
        "description": "Current Flux Timer settings (theme, font, palette, alerts defaults, snap config)",
        "mimeType": "application/json"
    ]
]
