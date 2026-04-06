import Foundation
import SwiftUI
import Combine

enum MenuBarDisplayMode: String, Codable, CaseIterable {
    case mostRecent = "Most Recent Timer"
    case allTimers = "All Timers"
    case iconOnly = "Icon Only"
}

enum TimerFont: String, Codable, CaseIterable, Identifiable {
    case sfRounded = "SF Pro Rounded"
    case sfMono = "SF Mono"
    case avenir = "Avenir Next"
    case futura = "Futura"
    case menlo = "Menlo"

    var id: String { rawValue }

    var swiftUIDesign: Font.Design {
        switch self {
        case .sfRounded: return .rounded
        case .sfMono: return .monospaced
        case .avenir, .futura, .menlo: return .default
        }
    }

    /// Returns nil for system fonts (use Font.Design), a name for named fonts
    var fontName: String? {
        switch self {
        case .sfRounded, .sfMono: return nil
        case .avenir: return "Avenir Next"
        case .futura: return "Futura Medium"
        case .menlo: return "Menlo"
        }
    }

    func font(size: CGFloat) -> Font {
        if let name = fontName {
            return .custom(name, size: size).monospacedDigit()
        }
        return .system(size: size, weight: .heavy, design: swiftUIDesign).monospacedDigit()
    }
}

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    // MARK: - Appearance

    @Published var defaultTheme: ThemeMode {
        didSet { save("defaultTheme", defaultTheme.rawValue) }
    }

    @Published var defaultPaletteId: String {
        didSet { save("defaultPaletteId", defaultPaletteId) }
    }

    @Published var timerFont: TimerFont {
        didSet { save("timerFont", timerFont.rawValue) }
    }

    @Published var fontSize: CGFloat {
        didSet { save("fontSize", fontSize) }
    }

    @Published var windowOpacity: Double {
        didSet { save("windowOpacity", windowOpacity) }
    }

    @Published var alwaysOnTop: Bool {
        didSet { save("alwaysOnTop", alwaysOnTop) }
    }

    @Published var showCentiseconds: Bool {
        didSet { save("showCentiseconds", showCentiseconds) }
    }

    // MARK: - Presets

    @Published var customPresets: [TimerPreset] {
        didSet {
            if let data = try? JSONEncoder().encode(customPresets) {
                UserDefaults.standard.set(data, forKey: "customPresets")
            }
        }
    }

    var allPresets: [TimerPreset] {
        TimerPreset.builtIn + customPresets
    }

    // MARK: - Alerts Defaults

    @Published var defaultAlerts: AlertConfiguration {
        didSet {
            if let data = try? JSONEncoder().encode(defaultAlerts) {
                UserDefaults.standard.set(data, forKey: "defaultAlerts")
            }
        }
    }

    @Published var alertSoundName: String {
        didSet { save("alertSoundName", alertSoundName) }
    }

    // MARK: - General

    @Published var launchAtLogin: Bool {
        didSet { save("launchAtLogin", launchAtLogin) }
    }

    @Published var menuBarDisplay: MenuBarDisplayMode {
        didSet { save("menuBarDisplay", menuBarDisplay.rawValue) }
    }

    @Published var snapThreshold: CGFloat {
        didSet { save("snapThreshold", snapThreshold) }
    }

    @Published var snapGap: CGFloat {
        didSet { save("snapGap", snapGap) }
    }

    // MARK: - Initialization

    private init() {
        let d = UserDefaults.standard

        self.defaultTheme = ThemeMode(rawValue: d.string(forKey: "defaultTheme") ?? "") ?? .gradient
        self.defaultPaletteId = d.string(forKey: "defaultPaletteId") ?? "solar_flare"
        self.timerFont = TimerFont(rawValue: d.string(forKey: "timerFont") ?? "") ?? .sfRounded
        self.fontSize = d.object(forKey: "fontSize") as? CGFloat ?? 42
        self.windowOpacity = d.object(forKey: "windowOpacity") as? Double ?? 1.0
        self.alwaysOnTop = d.object(forKey: "alwaysOnTop") as? Bool ?? true
        self.showCentiseconds = d.object(forKey: "showCentiseconds") as? Bool ?? false
        self.alertSoundName = d.string(forKey: "alertSoundName") ?? "Glass"
        self.launchAtLogin = d.object(forKey: "launchAtLogin") as? Bool ?? false
        self.menuBarDisplay = MenuBarDisplayMode(rawValue: d.string(forKey: "menuBarDisplay") ?? "") ?? .mostRecent
        self.snapThreshold = d.object(forKey: "snapThreshold") as? CGFloat ?? 20
        self.snapGap = d.object(forKey: "snapGap") as? CGFloat ?? 0

        if let alertData = d.data(forKey: "defaultAlerts"),
           let alerts = try? JSONDecoder().decode(AlertConfiguration.self, from: alertData) {
            self.defaultAlerts = alerts
        } else {
            self.defaultAlerts = AlertConfiguration()
        }

        if let presetData = d.data(forKey: "customPresets"),
           let presets = try? JSONDecoder().decode([TimerPreset].self, from: presetData) {
            self.customPresets = presets
        } else {
            self.customPresets = []
        }
    }

    private func save(_ key: String, _ value: Any) {
        UserDefaults.standard.set(value, forKey: key)
    }

    var defaultPalette: GradientPalette {
        GradientPalette.all.first { $0.id == defaultPaletteId } ?? .solarFlare
    }

    // MARK: - JSON for MCP

    func toJSON() -> [String: Any] {
        [
            "theme": defaultTheme.rawValue,
            "palette": defaultPaletteId,
            "font": timerFont.rawValue,
            "font_size": fontSize,
            "window_opacity": windowOpacity,
            "always_on_top": alwaysOnTop,
            "show_centiseconds": showCentiseconds,
            "alert_sound": alertSoundName,
            "launch_at_login": launchAtLogin,
            "menu_bar_display": menuBarDisplay.rawValue,
            "snap_threshold": snapThreshold,
            "snap_gap": snapGap,
            "default_alerts": [
                "sound": defaultAlerts.soundEnabled,
                "notification": defaultAlerts.notificationEnabled,
                "flash": defaultAlerts.flashEnabled
            ],
            "custom_presets": customPresets.map { ["label": $0.label, "duration": $0.duration] }
        ]
    }
}
