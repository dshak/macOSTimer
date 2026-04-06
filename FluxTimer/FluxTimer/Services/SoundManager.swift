import AppKit
import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    private var player: AVAudioPlayer?

    func playCompletionSound() {
        // Use system sound "Glass" as default — ships with macOS
        if let sound = NSSound(named: "Glass") {
            sound.play()
        }
    }
}
