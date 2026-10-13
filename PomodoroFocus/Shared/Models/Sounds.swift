import Foundation

/// Looping background sound played during focus blocks.
enum AmbientSound: String, Codable, CaseIterable, Identifiable {
    case silent = "none"
    case tickTock = "tickTick"
    case softTick
    case brownNoise
    case rain

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .silent: return "Silent"
        case .tickTock: return "Tick-tock"
        case .softTick: return "Soft tick"
        case .brownNoise: return "Brown noise"
        case .rain: return "Rain"
        }
    }

    var systemImage: String {
        switch self {
        case .silent: return "speaker.slash"
        case .tickTock: return "clock"
        case .softTick: return "metronome"
        case .brownNoise: return "waveform"
        case .rain: return "cloud.rain"
        }
    }

    /// Basename of the bundled loop in iOS/Resources/Sounds.
    var fileName: String? {
        switch self {
        case .silent: return nil
        case .tickTock: return "ambient_tick_tock"
        case .softTick: return "ambient_soft_tick"
        case .brownNoise: return "ambient_brown_noise"
        case .rain: return "ambient_rain"
        }
    }

    init(from decoder: Decoder) throws {
        // Older builds stored sounds that no longer exist (e.g. "cafe").
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = AmbientSound(rawValue: raw) ?? .tickTock
    }
}

/// One-shot sound played when a block ends.
enum AlertSound: String, Codable, CaseIterable, Identifiable {
    case silent = "none"
    case chime
    case bell
    case digital
    case bowl

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .silent: return "None"
        case .chime: return "Chime"
        case .bell: return "Bell"
        case .digital: return "Digital"
        case .bowl: return "Singing bowl"
        }
    }

    var fileName: String? {
        switch self {
        case .silent: return nil
        case .chime: return "alert_chime"
        case .bell: return "alert_bell"
        case .digital: return "alert_digital"
        case .bowl: return "alert_bowl"
        }
    }

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = AlertSound(rawValue: raw) ?? .chime
    }
}

/// Per-preset / per-routine sound override. nil means "use the app default".
struct SoundChoice: Codable, Hashable {
    var ambient: AmbientSound?
    var end: AlertSound?

    init(ambient: AmbientSound? = nil, end: AlertSound? = nil) {
        self.ambient = ambient
        self.end = end
    }
}
