import Foundation

struct Project: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var colorHex: String
    var isActive: Bool
    var createdAt: Date

    init(id: UUID = UUID(),
         name: String,
         colorHex: String = "#4F8EF7",
         isActive: Bool = true,
         createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.isActive = isActive
        self.createdAt = createdAt
    }
}

extension Project {
    /// Hard cap requested by the user. Enforced in AppStore.addProject.
    static let maxActive = 5
}
