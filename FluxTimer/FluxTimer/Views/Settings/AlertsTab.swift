import SwiftUI

struct AlertsTab: View {
    @ObservedObject private var settings = AppSettings.shared

    private let systemSounds = ["Glass", "Basso", "Blow", "Bottle", "Frog", "Funk", "Hero",
                                "Morse", "Ping", "Pop", "Purr", "Sosumi", "Submarine", "Tink"]

    var body: some View {
        Form {
            Section {
                Text("These are defaults for new timers. Each timer can override individually.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            // Sound
            Picker("Alert Sound", selection: $settings.alertSoundName) {
                ForEach(systemSounds, id: \.self) { name in
                    Text(name).tag(name)
                }
            }

            Button("Preview Sound") {
                if let sound = NSSound(named: NSSound.Name(settings.alertSoundName)) {
                    sound.play()
                }
            }

            Divider()

            // Default toggles
            Toggle("Sound Alert", isOn: $settings.defaultAlerts.soundEnabled)
            Toggle("Notification Alert", isOn: $settings.defaultAlerts.notificationEnabled)
            Toggle("Flash Alert", isOn: $settings.defaultAlerts.flashEnabled)
        }
        .formStyle(.grouped)
        .padding()
    }
}
