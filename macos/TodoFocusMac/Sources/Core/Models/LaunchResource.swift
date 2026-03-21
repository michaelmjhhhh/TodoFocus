import Foundation

enum LaunchResourceType: String, Codable {
    case url
    case file
    case app
}

struct LaunchResource: Equatable, Codable {
    let id: String
    let type: LaunchResourceType
    let label: String
    let value: String
    let createdAt: Date
}
