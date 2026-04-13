import Foundation
import AVFoundation
import Combine

/// Plays a looping ambient sound while a focus step is active. The asset is
/// any loopable file dropped into iOS/Resources/Sounds (e.g. tick.caf).
@MainActor
final class AmbientAudio: ObservableObject {
    @Published private(set) var isMuted: Bool = false
    private var player: AVAudioPlayer?
    private var currentSound: AmbientSound = .none
    private var volume: Double = 0.6

    func setMuted(_ muted: Bool) {
        isMuted = muted
        player?.volume = muted ? 0 : Float(volume)
    }

    func toggleMuted() { setMuted(!isMuted) }

    /// Call when the user opens the app / session starts.
    func configureSession() {
        let s = AVAudioSession.sharedInstance()
        try? s.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? s.setActive(true, options: [])
    }

    func apply(settings: AppSettings) {
        self.volume = settings.ambientVolume
        self.currentSound = settings.ambientSound
        player?.volume = Float(volume)
    }

    func start(_ sound: AmbientSound, volume: Double) {
        self.volume = volume
        self.currentSound = sound
        if isMuted {
            // Respect mute — load nothing; Unmuting will re-call start().
            stop()
            return
        }
        guard let name = sound.fileName else {
            stop()
            return
        }
        // Try .caf, then .mp3, then .wav
        let candidates = ["caf", "mp3", "wav", "m4a"]
        var url: URL?
        for ext in candidates {
            if let u = Bundle.main.url(forResource: name, withExtension: ext) {
                url = u; break
            }
        }
        guard let url else {
            // Silently no-op if the asset isn't bundled yet — user can drop one in later.
            stop()
            return
        }
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.numberOfLoops = -1
            p.volume = Float(volume)
            p.prepareToPlay()
            p.play()
            player = p
        } catch {
            stop()
        }
    }

    func stop() {
        player?.stop()
        player = nil
    }
}
