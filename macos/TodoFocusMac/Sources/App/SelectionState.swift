import Foundation

enum SidebarSelection: Equatable {
    case myDay
    case important
    case planned
    case all
    case customList(String)

    var smartList: SmartList {
        switch self {
        case .myDay:
            return .myDay
        case .important:
            return .important
        case .planned:
            return .planned
        case .all:
            return .all
        case let .customList(id):
            return .custom(listId: id)
        }
    }
}
