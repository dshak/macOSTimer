import SwiftUI

struct AppearanceTab: View {
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        Form {
            // Theme
            Picker("Theme", selection: $settings.defaultTheme) {
                ForEach(ThemeMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue.capitalized).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            // Palette
            VStack(alignment: .leading, spacing: 8) {
                Text("Palette")
                    .font(.headline)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 8) {
                    ForEach(GradientPalette.all) { palette in
                        PaletteSwatch(
                            palette: palette,
                            isSelected: settings.defaultPaletteId == palette.id
                        ) {
                            settings.defaultPaletteId = palette.id
                        }
                    }
                }
            }

            Divider()

            // Font
            Picker("Font", selection: $settings.timerFont) {
                ForEach(TimerFont.allCases) { font in
                    Text("12:34:56")
                        .font(font.font(size: 16))
                        .tag(font)
                }
            }

            // Font size
            HStack {
                Text("Font Size")
                Slider(value: $settings.fontSize, in: 24...48, step: 2)
                Text("\(Int(settings.fontSize))pt")
                    .monospacedDigit()
                    .frame(width: 36, alignment: .trailing)
            }

            // Live preview
            HStack {
                Spacer()
                Text("12:34:56")
                    .font(settings.timerFont.font(size: settings.fontSize))
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary))

            Divider()

            // Opacity
            HStack {
                Text("Window Opacity")
                Slider(value: $settings.windowOpacity, in: 0.4...1.0, step: 0.05)
                Text("\(Int(settings.windowOpacity * 100))%")
                    .monospacedDigit()
                    .frame(width: 36, alignment: .trailing)
            }

            // Toggles
            Toggle("Always on Top", isOn: $settings.alwaysOnTop)
            Toggle("Show Centiseconds", isOn: $settings.showCentiseconds)
        }
        .formStyle(.grouped)
        .padding()
    }
}

private struct PaletteSwatch: View {
    let palette: GradientPalette
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(colors: palette.startColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 52, height: 32)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2)
                    )
                    .shadow(color: isSelected ? Color.accentColor.opacity(0.4) : .clear, radius: 4)

                Text(palette.name)
                    .font(.system(size: 9))
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.spring(duration: 0.15), value: isHovered)
        .onHover { isHovered = $0 }
    }
}
