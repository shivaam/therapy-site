import Foundation

/// Free-form note dropped into the scratchpad. Append-only log of thoughts
/// captured during or between sessions. Shown newest-first.
struct ScratchpadEntry: Identifiable, Codable, Hashable {
    var id: UUID
    var text: String
    var createdAt: Date

    init(id: UUID = UUID(), text: String, createdAt: Date = .now) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
    }
}

/// Something that pulled your attention mid-session but isn't what you're
/// working on right now. Park it so it doesn't derail the current focus.
struct ParkingLotItem: Identifiable, Codable, Hashable {
    var id: UUID
    var text: String
    var done: Bool
    var createdAt: Date

    init(id: UUID = UUID(),
         text: String,
         done: Bool = false,
         createdAt: Date = .now) {
        self.id = id
        self.text = text
        self.done = done
        self.createdAt = createdAt
    }
}
