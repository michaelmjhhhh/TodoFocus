import Foundation

enum WindowPersistence {
    static let detailWidthKey = "todofocus-detail-width"

    static func loadDetailWidth(defaultValue: Double = 380) -> Double {
        let value = UserDefaults.standard.double(forKey: detailWidthKey)
        if value <= 0 {
            return defaultValue
        }
        return value
    }

    static func saveDetailWidth(_ value: Double) {
        UserDefaults.standard.set(value, forKey: detailWidthKey)
    }

    static func clampDetailWidth(_ value: Double, windowWidth: Double) -> Double {
        let minWidth = 340.0
        let maxWidth = min(760.0, max(minWidth, windowWidth - 460.0))
        return min(max(value, minWidth), maxWidth)
    }
}
