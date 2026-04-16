import SwiftUI

struct ListColor: Identifiable, Hashable {
    let id: String
    let name: String
    let color: Color

    init(hex: String, name: String) {
        self.id = hex
        self.name = name
        self.color = Color(hex: hex)
    }

    static let all: [ListColor] = [
        ListColor(hex: "#EF4444", name: "Red"),
        ListColor(hex: "#F97316", name: "Orange"),
        ListColor(hex: "#EAB308", name: "Yellow"),
        ListColor(hex: "#22C55E", name: "Green"),
        ListColor(hex: "#06B6D4", name: "Cyan"),
        ListColor(hex: "#3B82F6", name: "Blue"),
        ListColor(hex: "#8B5CF6", name: "Violet"),
        ListColor(hex: "#EC4899", name: "Pink"),
        ListColor(hex: "#6366F1", name: "Indigo"),
        ListColor(hex: "#14B8A6", name: "Teal")
    ]

    static func name(for hex: String) -> String {
        all.first(where: { $0.id == hex })?.name ?? "Custom Color"
    }
}
