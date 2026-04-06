import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            AppearanceTab()
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
            PresetsTab()
                .tabItem { Label("Presets", systemImage: "clock") }
            AlertsTab()
                .tabItem { Label("Alerts", systemImage: "bell") }
            GeneralTab()
                .tabItem { Label("General", systemImage: "gearshape") }
        }
        .frame(width: 420, height: 380)
    }
}
