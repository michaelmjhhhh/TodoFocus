import Foundation

enum WindowPersistence {
    static let detailWidthKey = "todofocus-detail-width"
    private static let widthSaveEpsilon = 0.5

    static func loadDetailWidth(defaultValue: Double = 380) -> Double {
        let value = UserDefaults.standard.double(forKey: detailWidthKey)
        if value <= 0 {
            return defaultValue
        }
        return value
    }

    static func saveDetailWidth(_ value: Double) {
        let defaults = UserDefaults.standard
        let existing = defaults.double(forKey: detailWidthKey)
        if existing > 0, abs(existing - value) < widthSaveEpsilon {
            return
        }
        defaults.set(value, forKey: detailWidthKey)
    }

    static func clampDetailWidth(_ value: Double, windowWidth: Double) -> Double {
        let minWidth = 340.0
        let maxWidth = min(760.0, max(minWidth, windowWidth - 460.0))
        return min(max(value, minWidth), maxWidth)
    }
}
