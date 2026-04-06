import Foundation

class SocketClient {
    private let socketPath: String

    init(socketPath: String = "/tmp/flux-timer.sock") {
        self.socketPath = socketPath
    }

    func send(request: FluxMCPRequest) throws -> FluxMCPResponse {
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else {
            throw SocketError.connectionFailed("Failed to create socket")
        }
        defer { close(fd) }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let pathBytes = socketPath.utf8CString
        withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
            ptr.withMemoryRebound(to: CChar.self, capacity: Int(104)) { dest in
                for (i, byte) in pathBytes.enumerated() where i < 104 {
                    dest[i] = byte
                }
            }
        }

        let addrLen = socklen_t(MemoryLayout<sockaddr_un>.size)
        let connectResult = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                Darwin.connect(fd, sockPtr, addrLen)
            }
        }

        guard connectResult == 0 else {
            throw SocketError.connectionFailed("Flux Timer is not running (cannot connect to \(socketPath))")
        }

        let encoder = JSONEncoder()
        var requestData = try encoder.encode(request)
        requestData.append(0x0A) // newline delimiter

        let written = requestData.withUnsafeBytes { ptr in
            Darwin.write(fd, ptr.baseAddress!, requestData.count)
        }
        guard written == requestData.count else {
            throw SocketError.writeFailed
        }

        // Read response
        var buffer = Data()
        let readBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 65536)
        defer { readBuffer.deallocate() }

        while true {
            let bytesRead = read(fd, readBuffer, 65536)
            if bytesRead <= 0 { break }
            buffer.append(readBuffer, count: bytesRead)
            if buffer.contains(0x0A) { break }
        }

        // Strip trailing newline
        if let newlineIndex = buffer.firstIndex(of: 0x0A) {
            buffer = buffer.subdata(in: buffer.startIndex..<newlineIndex)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(FluxMCPResponse.self, from: buffer)
    }
}

// Local types that mirror FluxProtocol but are self-contained for the MCP server target
struct FluxMCPRequest: Codable {
    let id: String
    let action: String
    let timerId: String?
    let params: [String: String]?
}

struct FluxMCPResponse: Codable {
    let id: String
    let success: Bool
    let data: String?
    let error: String?
}

enum SocketError: Error, LocalizedError {
    case connectionFailed(String)
    case writeFailed
    case readFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .connectionFailed(let msg): return msg
        case .writeFailed: return "Failed to write to socket"
        case .readFailed: return "Failed to read from socket"
        case .decodingFailed: return "Failed to decode response"
        }
    }
}
