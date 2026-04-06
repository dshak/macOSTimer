import Foundation

struct TimerPreset: Codable, Identifiable, Equatable {
    let id: UUID
    var label: String
    var duration: TimeInterval
    var isBuiltIn: Bool

    static let builtIn: [TimerPreset] = [
        TimerPreset(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                    label: "30 min", duration: 1800, isBuiltIn: true),
        TimerPreset(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                    label: "1 hour", duration: 3600, isBuiltIn: true),
        TimerPreset(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
                    label: "2 hours", duration: 7200, isBuiltIn: true),
    ]
}
