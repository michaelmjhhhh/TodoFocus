import Foundation

struct ListColor {
    static func name(for hex: String) -> String {
        switch hex.uppercased() {
        case "#EF4444": return "Red"
        case "#F97316": return "Orange"
        case "#EAB308": return "Yellow"
        case "#22C55E": return "Green"
        case "#06B6D4": return "Cyan"
        case "#3B82F6": return "Blue"
        case "#8B5CF6": return "Violet"
        case "#EC4899": return "Pink"
        case "#6366F1": return "Indigo"
        case "#14B8A6": return "Teal"
        default: return "Custom Color"
        }
    }
}
