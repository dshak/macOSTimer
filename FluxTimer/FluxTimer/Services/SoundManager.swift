import AppKit
import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    private var player: AVAudioPlayer?

    func playCompletionSound() {
        let soundName = AppSettings.shared.alertSoundName
        if let sound = NSSound(named: NSSound.Name(soundName)) {
            sound.play()
        }
    }
}
