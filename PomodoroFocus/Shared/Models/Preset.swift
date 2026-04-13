import Foundation

/// A reusable sequence of focus + break steps.
/// Example: 4 sessions with first two at 45m focus, last two at 25m focus,
/// 5m breaks in between, long break at the end.
struct Preset: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var steps: [SessionStep]
    /// When true the sequence loops; otherwise ends after the last step.
    var loop: Bool
    var createdAt: Date

    init(id: UUID = UUID(),
         name: String,
         steps: [SessionStep],
         loop: Bool = false,
         createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.steps = steps
        self.loop = loop
        self.createdAt = createdAt
    }

    var totalDurationSeconds: Int {
        steps.reduce(0) { $0 + $1.durationSeconds }
    }

    var focusCount: Int {
        steps.filter { $0.kind == .focus }.count
    }
}

extension Preset {
    /// Seed data so new installs have something to try immediately.
    static let defaults: [Preset] = [
        Preset(
            name: "Classic 25/5",
            steps: [
                .init(kind: .focus, durationSeconds: 25 * 60),
                .init(kind: .shortBreak, durationSeconds: 5 * 60),
                .init(kind: .focus, durationSeconds: 25 * 60),
                .init(kind: .shortBreak, durationSeconds: 5 * 60),
                .init(kind: .focus, durationSeconds: 25 * 60),
                .init(kind: .shortBreak, durationSeconds: 5 * 60),
                .init(kind: .focus, durationSeconds: 25 * 60),
                .init(kind: .longBreak, durationSeconds: 15 * 60),
            ]
        ),
        Preset(
            name: "Deep Work 45+25",
            steps: [
                .init(kind: .focus, durationSeconds: 45 * 60),
                .init(kind: .shortBreak, durationSeconds: 10 * 60),
                .init(kind: .focus, durationSeconds: 45 * 60),
                .init(kind: .shortBreak, durationSeconds: 10 * 60),
                .init(kind: .focus, durationSeconds: 25 * 60),
                .init(kind: .shortBreak, durationSeconds: 5 * 60),
                .init(kind: .focus, durationSeconds: 25 * 60),
                .init(kind: .longBreak, durationSeconds: 20 * 60),
            ]
        ),
    ]
}
