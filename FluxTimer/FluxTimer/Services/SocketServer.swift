import Foundation

class SocketServer {
    static let shared = SocketServer()

    private var socketFD: Int32 = -1
    private var listenSource: DispatchSourceRead?
    private let queue = DispatchQueue(label: "com.fluxtimer.socket", qos: .utility)

    weak var windowManager: WindowManager?

    func start() {
        cleanup()

        socketFD = socket(AF_UNIX, SOCK_STREAM, 0)
        guard socketFD >= 0 else {
            print("[SocketServer] Failed to create socket")
            return
        }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let pathBytes = fluxSocketPath.utf8CString
        withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
            ptr.withMemoryRebound(to: CChar.self, capacity: Int(104)) { dest in
                for (i, byte) in pathBytes.enumerated() where i < 104 {
                    dest[i] = byte
                }
            }
        }

        let addrLen = socklen_t(MemoryLayout<sockaddr_un>.size)
        withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                Darwin.bind(socketFD, sockPtr, addrLen)
            }
        }

        Darwin.listen(socketFD, 5)

        let source = DispatchSource.makeReadSource(fileDescriptor: socketFD, queue: queue)
        source.setEventHandler { [weak self] in
            self?.acceptConnection()
        }
        source.setCancelHandler { [weak self] in
            if let fd = self?.socketFD, fd >= 0 {
                close(fd)
            }
        }
        source.resume()
        listenSource = source

        print("[SocketServer] Listening on \(fluxSocketPath)")
    }

    func shutdown() {
        listenSource?.cancel()
        listenSource = nil
        cleanup()
    }

    private func cleanup() {
        unlink(fluxSocketPath)
        if socketFD >= 0 {
            close(socketFD)
            socketFD = -1
        }
    }

    private func acceptConnection() {
        var clientAddr = sockaddr_un()
        var clientAddrLen = socklen_t(MemoryLayout<sockaddr_un>.size)
        let clientFD = withUnsafeMutablePointer(to: &clientAddr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                Darwin.accept(socketFD, sockPtr, &clientAddrLen)
            }
        }
        guard clientFD >= 0 else { return }

        queue.async { [weak self] in
            self?.handleClient(fd: clientFD)
        }
    }

    private func handleClient(fd: Int32) {
        defer { close(fd) }

        var buffer = Data()
        let readBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 4096)
        defer { readBuffer.deallocate() }

        while true {
            let bytesRead = read(fd, readBuffer, 4096)
            if bytesRead <= 0 { break }
            buffer.append(readBuffer, count: bytesRead)

            while let newlineRange = buffer.range(of: Data([0x0A])) {
                let lineData = buffer.subdata(in: buffer.startIndex..<newlineRange.lowerBound)
                buffer.removeSubrange(buffer.startIndex...newlineRange.lowerBound)

                if let request = try? JSONDecoder().decode(FluxRequest.self, from: lineData) {
                    let response = processRequest(request)
                    if let responseData = try? JSONEncoder().encode(response) {
                        var toSend = responseData
                        toSend.append(0x0A) // newline delimiter
                        toSend.withUnsafeBytes { ptr in
                            _ = Darwin.write(fd, ptr.baseAddress!, toSend.count)
                        }
                    }
                }
            }

            if buffer.isEmpty { break }
        }
    }

    private func processRequest(_ request: FluxRequest) -> FluxResponse {
        guard let action = FluxAction(rawValue: request.action) else {
            return .fail(id: request.id, error: "Unknown action: \(request.action)")
        }

        guard let wm = windowManager else {
            return .fail(id: request.id, error: "Window manager not available")
        }

        switch action {
        case .create:
            let modeStr = request.params?["mode"] ?? "countdown"
            let mode = TimerMode(rawValue: modeStr) ?? .countdown
            let duration = TimeInterval(request.params?["duration"] ?? "1800") ?? 1800
            let label = request.params?["label"] ?? ""

            var resultData: [String: Any] = [:]
            let semaphore = DispatchSemaphore(value: 0)
            DispatchQueue.main.async {
                let model = wm.createTimer(mode: mode, duration: duration, label: label)
                resultData = model.toJSON()
                semaphore.signal()
            }
            semaphore.wait()
            return .ok(id: request.id, data: resultData)

        case .start:
            guard let timerId = request.timerId else {
                return .fail(id: request.id, error: "timer_id required")
            }
            var resultData: [String: Any] = [:]
            let semaphore = DispatchSemaphore(value: 0)
            DispatchQueue.main.async {
                if let engine = wm.engine(for: timerId) {
                    engine.start()
                    if let model = wm.timerModel(for: timerId) {
                        resultData = model.toJSON()
                    }
                }
                semaphore.signal()
            }
            semaphore.wait()
            if resultData.isEmpty {
                return .fail(id: request.id, error: "Timer not found: \(timerId)")
            }
            return .ok(id: request.id, data: resultData)

        case .pause:
            guard let timerId = request.timerId else {
                return .fail(id: request.id, error: "timer_id required")
            }
            var resultData: [String: Any] = [:]
            let semaphore = DispatchSemaphore(value: 0)
            DispatchQueue.main.async {
                if let engine = wm.engine(for: timerId) {
                    engine.pause()
                    if let model = wm.timerModel(for: timerId) {
                        resultData = model.toJSON()
                    }
                }
                semaphore.signal()
            }
            semaphore.wait()
            if resultData.isEmpty {
                return .fail(id: request.id, error: "Timer not found: \(timerId)")
            }
            return .ok(id: request.id, data: resultData)

        case .reset:
            guard let timerId = request.timerId else {
                return .fail(id: request.id, error: "timer_id required")
            }
            var resultData: [String: Any] = [:]
            let semaphore = DispatchSemaphore(value: 0)
            DispatchQueue.main.async {
                if let engine = wm.engine(for: timerId) {
                    engine.reset()
                    if let model = wm.timerModel(for: timerId) {
                        resultData = model.toJSON()
                    }
                }
                semaphore.signal()
            }
            semaphore.wait()
            if resultData.isEmpty {
                return .fail(id: request.id, error: "Timer not found: \(timerId)")
            }
            return .ok(id: request.id, data: resultData)

        case .stop:
            guard let timerId = request.timerId else {
                return .fail(id: request.id, error: "timer_id required")
            }
            var resultData: [String: Any] = [:]
            let semaphore = DispatchSemaphore(value: 0)
            DispatchQueue.main.async {
                if let engine = wm.engine(for: timerId) {
                    if let model = wm.timerModel(for: timerId) {
                        resultData = ["timer_id": timerId, "final_elapsed": model.elapsed]
                    }
                    engine.stop()
                    wm.closeTimer(id: timerId)
                }
                semaphore.signal()
            }
            semaphore.wait()
            if resultData.isEmpty {
                return .fail(id: request.id, error: "Timer not found: \(timerId)")
            }
            return .ok(id: request.id, data: resultData)

        case .get:
            guard let timerId = request.timerId else {
                return .fail(id: request.id, error: "timer_id required")
            }
            var resultData: [String: Any] = [:]
            let semaphore = DispatchSemaphore(value: 0)
            DispatchQueue.main.async {
                if let model = wm.timerModel(for: timerId) {
                    resultData = model.toJSON()
                }
                semaphore.signal()
            }
            semaphore.wait()
            if resultData.isEmpty {
                return .fail(id: request.id, error: "Timer not found: \(timerId)")
            }
            return .ok(id: request.id, data: resultData)

        case .list:
            var resultData: [[String: Any]] = []
            let semaphore = DispatchSemaphore(value: 0)
            DispatchQueue.main.async {
                resultData = wm.allTimerModels().map { $0.toJSON() }
                semaphore.signal()
            }
            semaphore.wait()
            return .ok(id: request.id, data: ["timers": resultData])

        case .update:
            guard let timerId = request.timerId else {
                return .fail(id: request.id, error: "timer_id required")
            }
            var resultData: [String: Any] = [:]
            let semaphore = DispatchSemaphore(value: 0)
            DispatchQueue.main.async {
                if let model = wm.timerModel(for: timerId) {
                    if let label = request.params?["label"] {
                        model.label = label
                    }
                    if let sound = request.params?["sound"] {
                        model.alerts.soundEnabled = (sound == "true")
                    }
                    if let notif = request.params?["notification"] {
                        model.alerts.notificationEnabled = (notif == "true")
                    }
                    if let flash = request.params?["flash"] {
                        model.alerts.flashEnabled = (flash == "true")
                    }
                    resultData = model.toJSON()
                }
                semaphore.signal()
            }
            semaphore.wait()
            if resultData.isEmpty {
                return .fail(id: request.id, error: "Timer not found: \(timerId)")
            }
            return .ok(id: request.id, data: resultData)

        case .history:
            let records = SessionHistoryManager.shared.load()
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let recordDicts: [[String: Any]] = records.compactMap { record in
                guard let data = try? encoder.encode(record),
                      let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    return nil
                }
                return dict
            }
            return .ok(id: request.id, data: ["history": recordDicts])
        }
    }
}
