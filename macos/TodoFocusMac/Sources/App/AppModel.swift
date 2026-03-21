import Foundation
import Observation

@Observable
final class AppModel {
    var activeViewID: String = "myday"
    var selectedTodoID: String?
    var detailPanelWidth: Double = 360
}
