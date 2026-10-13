import SwiftUI

extension Color {
    init(hex: String) {
        let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: trimmed).scanHexInt64(&value)
        guard trimmed.count == 6 else {
            self.init(red: 0.5, green: 0.5, blue: 0.5)
            return
        }
        self.init(red: Double((value & 0xFF0000) >> 16) / 255.0,
                  green: Double((value & 0x00FF00) >> 8) / 255.0,
                  blue: Double(value & 0x0000FF) / 255.0)
    }

    static let focusDefault = Color(hex: "#FF6B4A")
    static let breakGreen = Color(hex: "#3FB68B")
    static let longBreakBlue = Color(hex: "#4F8EF7")
}
