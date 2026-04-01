import Foundation
import Observation

struct DeepFocusSessionTemplate: Codable, Equatable, Identifiable {
    let id: String
    var name: String
    var durationMinutes: Int?
    var blockedApps: [String]
}

@Observable
final class DeepFocusTemplateStore {
    private let defaults: UserDefaults
    private let key: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    var templates: [DeepFocusSessionTemplate] = []

    init(defaults: UserDefaults = .standard, key: String = "deep_focus_session_templates_v1") {
        self.defaults = defaults
        self.key = key
        reload()
    }

    func reload() {
        guard let data = defaults.data(forKey: key),
              let decoded = try? decoder.decode([DeepFocusSessionTemplate].self, from: data) else {
            templates = []
            return
        }
        templates = decoded
    }

    @discardableResult
    func createTemplate(name: String, durationMinutes: Int?, blockedApps: [String]) -> DeepFocusSessionTemplate {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedDuration = durationMinutes.map { max(1, min(480, $0)) }
        let normalizedBlockedApps = Array(Set(blockedApps)).sorted()
        let template = DeepFocusSessionTemplate(
            id: UUID().uuidString,
            name: trimmed,
            durationMinutes: normalizedDuration,
            blockedApps: normalizedBlockedApps
        )
        templates.insert(template, at: 0)
        persist()
        return template
    }

    func renameTemplate(id: String, name: String) {
        guard let idx = templates.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        templates[idx].name = trimmed
        persist()
    }

    func deleteTemplate(id: String) {
        templates.removeAll { $0.id == id }
        persist()
    }

    private func persist() {
        guard let data = try? encoder.encode(templates) else { return }
        defaults.set(data, forKey: key)
    }
}
