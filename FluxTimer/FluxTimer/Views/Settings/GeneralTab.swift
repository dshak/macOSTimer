import SwiftUI
import ServiceManagement

struct GeneralTab: View {
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        Form {
            // Launch at login
            Toggle("Launch at Login", isOn: Binding(
                get: { settings.launchAtLogin },
                set: { newValue in
                    settings.launchAtLogin = newValue
                    updateLoginItem(enabled: newValue)
                }
            ))

            Divider()

            // Menu bar display
            Picker("Menu Bar Display", selection: $settings.menuBarDisplay) {
                ForEach(MenuBarDisplayMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }

            Divider()

            // Snap settings
            HStack {
                Text("Snap Threshold")
                Slider(value: $settings.snapThreshold, in: 10...40, step: 5)
                Text("\(Int(settings.snapThreshold))pt")
                    .monospacedDigit()
                    .frame(width: 36, alignment: .trailing)
            }

            Picker("Snap Gap", selection: $settings.snapGap) {
                Text("0pt (touching)").tag(CGFloat(0))
                Text("2pt (slight gap)").tag(CGFloat(2))
            }

            Divider()

            // About
            HStack {
                VStack(alignment: .leading) {
                    Text("Flux Timer")
                        .font(.headline)
                    Text("Version 1.0.0")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func updateLoginItem(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Login item error: \(error)")
            }
        }
    }
}
