import Foundation

/// One block in a running sequence. Derived from a preset's rounds rather than
/// stored, so editing a preset can never leave the two out of sync.
struct SessionStep: Identifiable, Hashable {
    enum Kind: String, Codable, CaseIterable, Identifiable {
        case focus
        case shortBreak
        case longBreak

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .focus: return "Focus"
            case .shortBreak: return "Break"
            case .longBreak: return "Long break"
            }
        }

        var isBreak: Bool { self != .focus }
    }

    /// Position in the sequence — stable for a given preset.
    var id: Int
    var kind: Kind
    var durationSeconds: Int
    /// 1-based round this step belongs to.
    var round: Int
}
