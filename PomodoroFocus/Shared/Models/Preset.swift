import Foundation

/// One focus block plus the break that follows it.
struct FocusRound: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var focusMinutes: Int
    /// Break after this round. Ignored on the last round, which is followed by
    /// the preset's long break instead.
    var breakMinutes: Int
}

enum TimeOfDay: String, Codable, CaseIterable, Identifiable {
    case any, morning, afternoon, evening

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .any: return "Any time"
        case .morning: return "Morning"
        case .afternoon: return "Afternoon"
        case .evening: return "Evening"
        }
    }

    static func current(_ date: Date = .now) -> TimeOfDay {
        switch Calendar.current.component(.hour, from: date) {
        case 4..<12: return .morning
        case 12..<17: return .afternoon
        default: return .evening
        }
    }
}

/// A saved rhythm, e.g. "Deep Work: 45 + 45 + 25 + 25 with breaks between".
struct Preset: Identifiable, Hashable {
    var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var rounds: [FocusRound]
    /// Break after the final round. 0 = none.
    var longBreakMinutes: Int
    var loop: Bool
    var bestTime: TimeOfDay
    var sounds: SoundChoice
    var createdAt: Date
    var lastUsedAt: Date?

    init(id: UUID = UUID(),
         name: String,
         icon: String = "timer",
         colorHex: String = "#FF6B4A",
         rounds: [FocusRound],
         longBreakMinutes: Int = 0,
         loop: Bool = false,
         bestTime: TimeOfDay = .any,
         sounds: SoundChoice = SoundChoice(),
         createdAt: Date = .now,
         lastUsedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.rounds = rounds
        self.longBreakMinutes = longBreakMinutes
        self.loop = loop
        self.bestTime = bestTime
        self.sounds = sounds
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
    }

    static func uniform(name: String,
                        icon: String,
                        colorHex: String,
                        rounds count: Int,
                        focus: Int,
                        breakMinutes: Int,
                        longBreak: Int,
                        bestTime: TimeOfDay = .any) -> Preset {
        Preset(name: name,
               icon: icon,
               colorHex: colorHex,
               rounds: (0..<max(1, count)).map { _ in FocusRound(focusMinutes: focus, breakMinutes: breakMinutes) },
               longBreakMinutes: longBreak,
               bestTime: bestTime)
    }

    static func newDraft() -> Preset {
        .uniform(name: "", icon: "timer", colorHex: "#FF6B4A",
                 rounds: 4, focus: 25, breakMinutes: 5, longBreak: 15)
    }

    // MARK: - Derived

    var steps: [SessionStep] {
        var out: [SessionStep] = []
        for (i, round) in rounds.enumerated() {
            out.append(SessionStep(id: out.count, kind: .focus,
                                   durationSeconds: round.focusMinutes * 60, round: i + 1))
            let isLast = i == rounds.count - 1
            if isLast {
                if longBreakMinutes > 0 {
                    out.append(SessionStep(id: out.count, kind: .longBreak,
                                           durationSeconds: longBreakMinutes * 60, round: i + 1))
                }
            } else if round.breakMinutes > 0 {
                out.append(SessionStep(id: out.count, kind: .shortBreak,
                                       durationSeconds: round.breakMinutes * 60, round: i + 1))
            }
        }
        return out
    }

    /// Index of the step after `index`, wrapping when the preset loops.
    func stepIndex(after index: Int) -> Int? {
        let count = steps.count
        if index + 1 < count { return index + 1 }
        return loop && count > 0 ? 0 : nil
    }

    var totalSeconds: Int { steps.reduce(0) { $0 + $1.durationSeconds } }

    /// True when every round has the same focus length and the same break.
    var isUniform: Bool {
        guard let first = rounds.first else { return true }
        let breaks = Set(rounds.dropLast().map(\.breakMinutes))
        return rounds.allSatisfy { $0.focusMinutes == first.focusMinutes } && breaks.count <= 1
    }

    /// "4 × 25 min · 5 min breaks" or "45 + 45 + 25 + 25 min".
    var summary: String {
        guard let first = rounds.first else { return "Empty" }
        if isUniform {
            var text = rounds.count == 1
                ? "\(first.focusMinutes) min"
                : "\(rounds.count) × \(first.focusMinutes) min"
            if rounds.count > 1, let gap = rounds.dropLast().first?.breakMinutes, gap > 0 {
                text += " · \(gap) min breaks"
            }
            return text
        }
        return rounds.map { "\($0.focusMinutes)" }.joined(separator: " + ") + " min"
    }
}

// MARK: - Codable (with migration from the old step-list format)

extension Preset: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, name, icon, colorHex, rounds, longBreakMinutes, loop, bestTime, sounds, createdAt, lastUsedAt
    }

    private enum LegacyKeys: String, CodingKey {
        case steps
    }

    private struct LegacyStep: Decodable {
        var kind: SessionStep.Kind
        var durationSeconds: Int
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        icon = try c.decodeIfPresent(String.self, forKey: .icon) ?? "timer"
        colorHex = try c.decodeIfPresent(String.self, forKey: .colorHex) ?? "#FF6B4A"
        loop = try c.decodeIfPresent(Bool.self, forKey: .loop) ?? false
        bestTime = try c.decodeIfPresent(TimeOfDay.self, forKey: .bestTime) ?? .any
        sounds = try c.decodeIfPresent(SoundChoice.self, forKey: .sounds) ?? SoundChoice()
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
        lastUsedAt = try c.decodeIfPresent(Date.self, forKey: .lastUsedAt)

        if let rounds = try c.decodeIfPresent([FocusRound].self, forKey: .rounds), !rounds.isEmpty {
            self.rounds = rounds
            longBreakMinutes = try c.decodeIfPresent(Int.self, forKey: .longBreakMinutes) ?? 0
            return
        }

        // Pre-rounds builds stored a flat list of focus/break steps.
        let legacy = try decoder.container(keyedBy: LegacyKeys.self)
        let steps = try legacy.decodeIfPresent([LegacyStep].self, forKey: .steps) ?? []
        var rounds: [FocusRound] = []
        for step in steps {
            switch step.kind {
            case .focus:
                rounds.append(FocusRound(focusMinutes: max(1, step.durationSeconds / 60), breakMinutes: 0))
            case .shortBreak, .longBreak:
                guard !rounds.isEmpty else { continue }
                rounds[rounds.count - 1].breakMinutes = step.durationSeconds / 60
            }
        }
        var longBreak = 0
        if let last = rounds.last, last.breakMinutes > 0 {
            longBreak = last.breakMinutes
            rounds[rounds.count - 1].breakMinutes = 0
        }
        self.rounds = rounds.isEmpty ? [FocusRound(focusMinutes: 25, breakMinutes: 5)] : rounds
        longBreakMinutes = longBreak
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(icon, forKey: .icon)
        try c.encode(colorHex, forKey: .colorHex)
        try c.encode(rounds, forKey: .rounds)
        try c.encode(longBreakMinutes, forKey: .longBreakMinutes)
        try c.encode(loop, forKey: .loop)
        try c.encode(bestTime, forKey: .bestTime)
        try c.encode(sounds, forKey: .sounds)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(lastUsedAt, forKey: .lastUsedAt)
    }
}

// MARK: - Defaults

extension Preset {
    /// Deliberately few: a low-barrier starter, the classic, and the
    /// mixed-length deep-work rhythm.
    static let defaults: [Preset] = [
        .uniform(name: "Quick Start", icon: "bolt.fill", colorHex: "#F5A524",
                 rounds: 1, focus: 15, breakMinutes: 0, longBreak: 5),
        .uniform(name: "Classic", icon: "timer", colorHex: "#FF6B4A",
                 rounds: 4, focus: 25, breakMinutes: 5, longBreak: 15),
        Preset(name: "Deep Work",
               icon: "brain.head.profile",
               colorHex: "#7C6CF2",
               rounds: [
                   FocusRound(focusMinutes: 45, breakMinutes: 10),
                   FocusRound(focusMinutes: 45, breakMinutes: 10),
                   FocusRound(focusMinutes: 25, breakMinutes: 5),
                   FocusRound(focusMinutes: 25, breakMinutes: 0),
               ],
               longBreakMinutes: 20,
               bestTime: .morning),
    ]
}
