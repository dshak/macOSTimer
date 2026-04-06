import Foundation

struct AlertConfiguration: Codable, Equatable {
    var soundEnabled: Bool = true
    var notificationEnabled: Bool = true
    var flashEnabled: Bool = true
}
