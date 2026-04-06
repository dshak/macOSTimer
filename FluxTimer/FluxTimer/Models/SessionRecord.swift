import Foundation

struct SessionRecord: Codable, Identifiable {
    let id: UUID
    let timerId: UUID
    var label: String
    var mode: TimerMode
    var configuredDuration: TimeInterval
    var actualElapsed: TimeInterval
    var startedAt: Date
    var completedAt: Date
    var completionReason: CompletionReason

    enum CompletionReason: String, Codable {
        case expired
        case stopped
        case finished
    }
}

class SessionHistoryManager {
    static let shared = SessionHistoryManager()

    private let fileURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("FluxTimer", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("session_history.json")
    }()

    private let maxEntries = 500

    func load() -> [SessionRecord] {
        guard let data = try? Data(contentsOf: fileURL),
              let records = try? JSONDecoder().decode([SessionRecord].self, from: data) else {
            return []
        }
        return records
    }

    func append(_ record: SessionRecord) {
        var records = load()
        records.append(record)
        if records.count > maxEntries {
            records = Array(records.suffix(maxEntries))
        }
        if let data = try? JSONEncoder().encode(records) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}
