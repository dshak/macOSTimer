import Foundation

class ResourceHandler {
    let client: SocketClient

    init(client: SocketClient) {
        self.client = client
    }

    func handle(uri: String) -> Any {
        switch uri {
        case "flux://history":
            return handleHistory()
        case "flux://timers":
            return handleTimers()
        default:
            return ["error": "Unknown resource: \(uri)"]
        }
    }

    private func handleHistory() -> Any {
        let request = FluxMCPRequest(
            id: UUID().uuidString,
            action: "history",
            timerId: nil,
            params: nil
        )

        do {
            let response = try client.send(request: request)
            if response.success, let dataString = response.data,
               let data = dataString.data(using: .utf8),
               let _ = try? JSONSerialization.jsonObject(with: data) {
                return [
                    "contents": [
                        [
                            "uri": "flux://history",
                            "mimeType": "application/json",
                            "text": dataString
                        ]
                    ]
                ]
            }
            return ["contents": [["uri": "flux://history", "mimeType": "application/json", "text": "[]"]]]
        } catch {
            return ["error": error.localizedDescription]
        }
    }

    private func handleTimers() -> Any {
        let request = FluxMCPRequest(
            id: UUID().uuidString,
            action: "list",
            timerId: nil,
            params: nil
        )

        do {
            let response = try client.send(request: request)
            if response.success, let dataString = response.data {
                return [
                    "contents": [
                        [
                            "uri": "flux://timers",
                            "mimeType": "application/json",
                            "text": dataString
                        ]
                    ]
                ]
            }
            return ["contents": [["uri": "flux://timers", "mimeType": "application/json", "text": "{}"]]]
        } catch {
            return ["error": error.localizedDescription]
        }
    }
}
