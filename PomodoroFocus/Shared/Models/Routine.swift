import Foundation

/// A single timed block with a checklist that stays on screen while it runs
/// (morning / night routines).
struct Routine: Identifiable, Hashable {
    enum Kind: String, Codable, CaseIterable, Identifiable {
        case morning
        case night
        case custom

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .morning: return "Morning"
            case .night: return "Night"
            case .custom: return "Other"
            }
        }

        var systemImage: String {
            switch self {
            case .morning: return "sunrise.fill"
            case .night: return "moon.stars.fill"
            case .custom: return "checklist"
            }
        }
    }

    var id: UUID
    var name: String
    var kind: Kind
    var totalSeconds: Int
    var tasks: [RoutineTask]
    var sounds: SoundChoice

    init(id: UUID = UUID(),
         name: String,
         kind: Kind,
         totalSeconds: Int,
         tasks: [RoutineTask],
         sounds: SoundChoice = SoundChoice()) {
        self.id = id
        self.name = name
        self.kind = kind
        self.totalSeconds = totalSeconds
        self.tasks = tasks
        self.sounds = sounds
    }
}

extension Routine: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, name, kind, totalSeconds, tasks, sounds
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        kind = try c.decodeIfPresent(Kind.self, forKey: .kind) ?? .custom
        totalSeconds = try c.decodeIfPresent(Int.self, forKey: .totalSeconds) ?? 600
        tasks = try c.decodeIfPresent([RoutineTask].self, forKey: .tasks) ?? []
        sounds = try c.decodeIfPresent(SoundChoice.self, forKey: .sounds) ?? SoundChoice()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(kind, forKey: .kind)
        try c.encode(totalSeconds, forKey: .totalSeconds)
        try c.encode(tasks, forKey: .tasks)
        try c.encode(sounds, forKey: .sounds)
    }
}

struct RoutineTask: Identifiable, Codable, Hashable {
    var id: UUID
    var text: String
    var done: Bool

    init(id: UUID = UUID(), text: String, done: Bool = false) {
        self.id = id
        self.text = text
        self.done = done
    }
}

extension Routine {
    static let defaults: [Routine] = [
        Routine(
            name: "Morning",
            kind: .morning,
            totalSeconds: 20 * 60,
            tasks: [
                .init(text: "Drink a glass of water"),
                .init(text: "Stretch for 5 minutes"),
                .init(text: "Pick today's top 3"),
                .init(text: "Breathe for 2 minutes"),
            ]
        ),
        Routine(
            name: "Night",
            kind: .night,
            totalSeconds: 15 * 60,
            tasks: [
                .init(text: "Clear the desk"),
                .init(text: "Brain-dump tomorrow's tasks"),
                .init(text: "Phone on the charger, away from bed"),
                .init(text: "Read a few pages"),
            ]
        ),
    ]
}
