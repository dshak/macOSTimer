import SwiftUI

enum ThemeMode: String, Codable, CaseIterable {
    case gradient
    case glass
}

struct GradientPalette: Identifiable, Equatable {
    let id: String
    let name: String
    /// 3 colors: start state
    let startColors: [Color]
    /// 3 colors: midpoint state (50% elapsed)
    let midColors: [Color]
    /// 3 colors: end state (100% elapsed / countdown complete)
    let endColors: [Color]

    /// Convenience: the start colors (used as the base display)
    var colors: [Color] { startColors }

    /// Interpolate between start → mid → end based on progress (0.0 to 1.0)
    func colors(at progress: Double) -> [Color] {
        let p = min(1, max(0, progress))
        if p <= 0.5 {
            let t = p / 0.5
            return zip(startColors, midColors).map { Color.lerp($0, $1, t: t) }
        } else {
            let t = (p - 0.5) / 0.5
            return zip(midColors, endColors).map { Color.lerp($0, $1, t: t) }
        }
    }

    static let solarFlare = GradientPalette(
        id: "solar_flare", name: "Solar Flare",
        startColors: [Color(hex: 0xFF6B35), Color(hex: 0xF72585), Color(hex: 0xB5179E)],
        midColors:   [Color(hex: 0xB5179E), Color(hex: 0x7209B7), Color(hex: 0x560BAD)],
        endColors:   [Color(hex: 0x560BAD), Color(hex: 0x480CA8), Color(hex: 0x3A0CA3)]
    )

    static let deepOcean = GradientPalette(
        id: "deep_ocean", name: "Deep Ocean",
        startColors: [Color(hex: 0x03045E), Color(hex: 0x0077B6), Color(hex: 0x0096C7)],
        midColors:   [Color(hex: 0x0096C7), Color(hex: 0x00B4D8), Color(hex: 0x48CAE4)],
        endColors:   [Color(hex: 0x48CAE4), Color(hex: 0x90E0EF), Color(hex: 0xCAF0F8)]
    )

    static let northernLights = GradientPalette(
        id: "northern_lights", name: "Northern Lights",
        startColors: [Color(hex: 0x06D6A0), Color(hex: 0x1B9AAA), Color(hex: 0x118AB2)],
        midColors:   [Color(hex: 0xEF476F), Color(hex: 0xF78C6B), Color(hex: 0xFFD166)],
        endColors:   [Color(hex: 0xFFD166), Color(hex: 0xFCEC52), Color(hex: 0xFFE66D)]
    )

    static let midnightEmber = GradientPalette(
        id: "midnight_ember", name: "Midnight Ember",
        startColors: [Color(hex: 0x1A1A2E), Color(hex: 0x16213E), Color(hex: 0x0F3460)],
        midColors:   [Color(hex: 0x0F3460), Color(hex: 0x533483), Color(hex: 0x7B2D8E)],
        endColors:   [Color(hex: 0xE94560), Color(hex: 0xFF6B6B), Color(hex: 0xFF8E8E)]
    )

    static let lavenderDusk = GradientPalette(
        id: "lavender_dusk", name: "Lavender Dusk",
        startColors: [Color(hex: 0xE0AAFF), Color(hex: 0xC77DFF), Color(hex: 0xB388FF)],
        midColors:   [Color(hex: 0x9D4EDD), Color(hex: 0x7B2CBF), Color(hex: 0x6A1CB0)],
        endColors:   [Color(hex: 0x5A189A), Color(hex: 0x3C096C), Color(hex: 0x240046)]
    )

    static let citrusBurst = GradientPalette(
        id: "citrus_burst", name: "Citrus Burst",
        startColors: [Color(hex: 0xF9C74F), Color(hex: 0xF9844A), Color(hex: 0xF8961E)],
        midColors:   [Color(hex: 0xF8961E), Color(hex: 0xF3722C), Color(hex: 0xF94144)],
        endColors:   [Color(hex: 0xF94144), Color(hex: 0xE71D36), Color(hex: 0xC9184A)]
    )

    static let all: [GradientPalette] = [
        .solarFlare, .deepOcean, .northernLights,
        .midnightEmber, .lavenderDusk, .citrusBurst
    ]
}

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }

    /// Extract HSB components
    var hsba: (h: Double, s: Double, b: Double, a: Double) {
        let nsColor = NSColor(self).usingColorSpace(.deviceRGB) ?? NSColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        nsColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return (Double(h), Double(s), Double(b), Double(a))
    }

    /// Linearly interpolate between two colors in HSB space
    static func lerp(_ a: Color, _ b: Color, t: Double) -> Color {
        let ca = a.hsba
        let cb = b.hsba

        // Handle hue wrapping (shortest path)
        var dh = cb.h - ca.h
        if dh > 0.5 { dh -= 1.0 }
        if dh < -0.5 { dh += 1.0 }

        let h = ca.h + dh * t
        let s = ca.s + (cb.s - ca.s) * t
        let br = ca.b + (cb.b - ca.b) * t
        let al = ca.a + (cb.a - ca.a) * t

        return Color(hue: (h + 1).truncatingRemainder(dividingBy: 1.0), saturation: s, brightness: br, opacity: al)
    }
}
