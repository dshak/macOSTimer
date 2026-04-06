import SwiftUI

struct PresetsTab: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var newLabel = ""
    @State private var newHours = 0
    @State private var newMinutes = 30
    @State private var newSeconds = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timer Presets")
                .font(.headline)

            // Built-in presets
            Section {
                ForEach(TimerPreset.builtIn) { preset in
                    PresetRow(label: preset.label, duration: preset.duration, isBuiltIn: true, onDelete: nil)
                }
            } header: {
                Text("Built-in")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Custom presets
            Section {
                if settings.customPresets.isEmpty {
                    Text("No custom presets")
                        .foregroundStyle(.tertiary)
                        .font(.callout)
                } else {
                    ForEach(settings.customPresets) { preset in
                        PresetRow(label: preset.label, duration: preset.duration, isBuiltIn: false) {
                            settings.customPresets.removeAll { $0.id == preset.id }
                        }
                    }
                }
            } header: {
                Text("Custom")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Add new preset
            HStack(spacing: 8) {
                TextField("Label", text: $newLabel)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)

                Stepper("\(newHours)h", value: $newHours, in: 0...23)
                    .frame(width: 70)
                Stepper("\(newMinutes)m", value: $newMinutes, in: 0...59)
                    .frame(width: 70)
                Stepper("\(newSeconds)s", value: $newSeconds, in: 0...59)
                    .frame(width: 70)

                Button(action: addPreset) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.green)
                }
                .buttonStyle(.plain)
                .disabled(newHours == 0 && newMinutes == 0 && newSeconds == 0)
            }
        }
        .padding()
    }

    private func addPreset() {
        let duration = TimeInterval(newHours * 3600 + newMinutes * 60 + newSeconds)
        let label = newLabel.isEmpty ? formatDuration(duration) : newLabel
        let preset = TimerPreset(id: UUID(), label: label, duration: duration, isBuiltIn: false)
        settings.customPresets.append(preset)
        newLabel = ""
        newMinutes = 30
        newHours = 0
        newSeconds = 0
    }

    private func formatDuration(_ d: TimeInterval) -> String {
        let h = Int(d) / 3600
        let m = (Int(d) % 3600) / 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}

private struct PresetRow: View {
    let label: String
    let duration: TimeInterval
    let isBuiltIn: Bool
    let onDelete: (() -> Void)?

    var body: some View {
        HStack {
            Text(label)
                .font(.body)

            Spacer()

            Text(formattedDuration)
                .foregroundStyle(.secondary)
                .monospacedDigit()

            if !isBuiltIn, let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(.red.opacity(0.7))
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 2)
    }

    private var formattedDuration: String {
        let h = Int(duration) / 3600
        let m = (Int(duration) % 3600) / 60
        let s = Int(duration) % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
}
