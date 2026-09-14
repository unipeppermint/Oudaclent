import UIKit
import AVFoundation

/// Short bundled effects respect the app preferences and the device silent switch.
enum GameFeedback {
    private static var player: AVAudioPlayer?

    static func spin() {
        if AppSettingsStore.shared.settings.vibrationEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        play("spin")
    }

    static func reward() {
        if AppSettingsStore.shared.settings.vibrationEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        play("reward")
    }

    private static func play(_ name: String) {
        guard AppSettingsStore.shared.settings.soundEnabled,
              let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = 0.3
            player?.play()
        } catch {
#if DEBUG
            print("[GameFeedback] Unable to play effect: \(error.localizedDescription)")
#endif
        }
    }
}
