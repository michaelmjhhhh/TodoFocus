import Foundation

enum SidebarSelection: Equatable {
    case dailyReview
    case myDay
    case important
    case planned
    case overdue
    case all
    case archive
    case customList(String)

    var smartList: SmartList {
        switch self {
        case .dailyReview:
            return .all
        case .myDay:
            return .myDay
        case .important:
            return .important
        case .planned:
            return .planned
        case .overdue:
            return .all
        case .all:
            return .all
        case .archive:
            return .archive
        case let .customList(id):
            return .custom(listId: id)
        }
    }
}
