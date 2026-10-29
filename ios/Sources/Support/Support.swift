import AVFoundation
import UIKit

enum Haptics {
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func miss() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
}

/// Leitura em voz alta (português do Brasil).
final class Speaker {
    static let shared = Speaker()
    private let synth = AVSpeechSynthesizer()

    func say(_ text: String) {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
        synth.stopSpeaking(at: .immediate)
        let clean = text.replacingOccurrences(of: "“", with: "").replacingOccurrences(of: "”", with: "")
        let u = AVSpeechUtterance(string: clean)
        u.voice = AVSpeechSynthesisVoice(language: "pt-BR")
        u.rate = 0.48
        synth.speak(u)
    }

    /// Falinhas da Lumi: voz mais aguda e respeitando o botão de silencioso do iPhone.
    func chatter(_ text: String) {
        guard UserDefaults.standard.object(forKey: "lumiVoice") as? Bool ?? true else { return }
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        synth.stopSpeaking(at: .immediate)
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: "pt-BR")
        u.rate = 0.5
        u.pitchMultiplier = 1.45
        u.volume = 0.9
        synth.speak(u)
    }

    func stop() { synth.stopSpeaking(at: .immediate) }
}
