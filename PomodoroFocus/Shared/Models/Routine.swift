import Foundation

/// A checklist-style timed routine (morning / night). Tasks are displayed
/// during the run so the user can follow them while the timer ticks.
struct Routine: Identifiable, Codable, Hashable {
    enum Kind: String, Codable, CaseIterable, Identifiable {
        case morning
        case night
        case custom

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .morning: return "Morning"
            case .night: return "Night"
            case .custom: return "Custom"
            }
        }

        var systemImage: String {
            switch self {
            case .morning: return "sunrise.fill"
            case .night: return "moon.stars.fill"
            case .custom: return "list.bullet.rectangle"
            }
        }
    }

    var id: UUID
    var name: String
    var kind: Kind
    var totalSeconds: Int
    var tasks: [RoutineTask]

    init(id: UUID = UUID(),
         name: String,
         kind: Kind,
         totalSeconds: Int,
         tasks: [RoutineTask]) {
        self.id = id
        self.name = name
        self.kind = kind
        self.totalSeconds = totalSeconds
        self.tasks = tasks
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
                .init(text: "5 minutes of stretching"),
                .init(text: "Cold face rinse"),
                .init(text: "Review top 3 priorities"),
                .init(text: "Silent breathing — 2 minutes"),
            ]
        ),
        Routine(
            name: "Night",
            kind: .night,
            totalSeconds: 15 * 60,
            tasks: [
                .init(text: "Tidy desk"),
                .init(text: "Brain dump tomorrow's tasks"),
                .init(text: "Skincare"),
                .init(text: "Read 5 pages"),
                .init(text: "Lights out"),
            ]
        ),
    ]
}
