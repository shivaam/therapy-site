import Foundation

/// A single step inside a preset. A step is either a focus block or a break.
struct SessionStep: Identifiable, Codable, Hashable {
    enum Kind: String, Codable, CaseIterable, Identifiable {
        case focus
        case shortBreak
        case longBreak

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .focus: return "Focus"
            case .shortBreak: return "Break"
            case .longBreak: return "Long Break"
            }
        }
    }

    var id: UUID
    var kind: Kind
    /// Duration in seconds. Stored this way so the Watch doesn't need to know about TimeInterval conventions.
    var durationSeconds: Int

    init(id: UUID = UUID(), kind: Kind, durationSeconds: Int) {
        self.id = id
        self.kind = kind
        self.durationSeconds = durationSeconds
    }

    var durationMinutes: Int {
        get { durationSeconds / 60 }
        set { durationSeconds = max(1, newValue) * 60 }
    }
}
