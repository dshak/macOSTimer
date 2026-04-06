import Foundation

class ToolHandler {
    let client: SocketClient

    init(client: SocketClient) {
        self.client = client
    }

    func handle(toolName: String, arguments: [String: AnyCodableValue]?) -> Any {
        switch toolName {
        case "flux_create_timer":
            return handleCreate(arguments)
        case "flux_start_timer":
            return handleTimerAction("start", arguments)
        case "flux_pause_timer":
            return handleTimerAction("pause", arguments)
        case "flux_reset_timer":
            return handleTimerAction("reset", arguments)
        case "flux_stop_timer":
            return handleTimerAction("stop", arguments)
        case "flux_get_timer":
            return handleTimerAction("get", arguments)
        case "flux_list_timers":
            return handleList()
        case "flux_update_timer":
            return handleUpdate(arguments)
        default:
            return ["error": "Unknown tool: \(toolName)"]
        }
    }

    private func handleCreate(_ args: [String: AnyCodableValue]?) -> Any {
        let mode = args?["mode"]?.stringValue ?? "countdown"
        let duration = args?["duration"]?.doubleValue ?? 1800
        let label = args?["label"]?.stringValue ?? ""

        let request = FluxMCPRequest(
            id: UUID().uuidString,
            action: "create",
            timerId: nil,
            params: [
                "mode": mode,
                "duration": String(Int(duration)),
                "label": label
            ]
        )

        return sendAndParse(request)
    }

    private func handleTimerAction(_ action: String, _ args: [String: AnyCodableValue]?) -> Any {
        guard let timerId = args?["timer_id"]?.stringValue else {
            return ["error": "timer_id is required"]
        }

        let request = FluxMCPRequest(
            id: UUID().uuidString,
            action: action,
            timerId: timerId,
            params: nil
        )

        return sendAndParse(request)
    }

    private func handleUpdate(_ args: [String: AnyCodableValue]?) -> Any {
        guard let timerId = args?["timer_id"]?.stringValue else {
            return ["error": "timer_id is required"]
        }

        var params: [String: String] = [:]
        if let label = args?["label"]?.stringValue {
            params["label"] = label
        }
        if let sound = args?["sound"] {
            if case .bool(let v) = sound { params["sound"] = v ? "true" : "false" }
        }
        if let notif = args?["notification"] {
            if case .bool(let v) = notif { params["notification"] = v ? "true" : "false" }
        }
        if let flash = args?["flash"] {
            if case .bool(let v) = flash { params["flash"] = v ? "true" : "false" }
        }

        let request = FluxMCPRequest(
            id: UUID().uuidString,
            action: "update",
            timerId: timerId,
            params: params.isEmpty ? nil : params
        )
        return sendAndParse(request)
    }

    private func handleList() -> Any {
        let request = FluxMCPRequest(
            id: UUID().uuidString,
            action: "list",
            timerId: nil,
            params: nil
        )
        return sendAndParse(request)
    }

    private func sendAndParse(_ request: FluxMCPRequest) -> Any {
        do {
            let response = try client.send(request: request)
            if response.success {
                if let dataString = response.data,
                   let data = dataString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) {
                    return json
                }
                return ["success": true]
            } else {
                return ["error": response.error ?? "Unknown error"]
            }
        } catch {
            return ["error": error.localizedDescription]
        }
    }
}
