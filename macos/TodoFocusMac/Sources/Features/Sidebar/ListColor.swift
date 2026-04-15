import SwiftUI

struct ListColor: Identifiable, Hashable {
    let id: String
    let name: String
    let hex: String

    init(name: String, hex: String) {
        self.id = hex
        self.name = name
        self.hex = hex
    }

    static let all: [ListColor] = [
        ListColor(name: "Red", hex: "#EF4444"),
        ListColor(name: "Orange", hex: "#F97316"),
        ListColor(name: "Yellow", hex: "#EAB308"),
        ListColor(name: "Green", hex: "#22C55E"),
        ListColor(name: "Cyan", hex: "#06B6D4"),
        ListColor(name: "Blue", hex: "#3B82F6"),
        ListColor(name: "Violet", hex: "#8B5CF6"),
        ListColor(name: "Pink", hex: "#EC4899"),
        ListColor(name: "Indigo", hex: "#6366F1"),
        ListColor(name: "Teal", hex: "#14B8A6")
    ]

    static func name(for hex: String) -> String {
        all.first(where: { $0.hex.uppercased() == hex.uppercased() })?.name ?? "Custom Color"
    }
}
