import Foundation

struct TodoItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var isCompleted = false
    var priority: Priority = .medium
    var createdAt = Date()

    enum Priority: String, Codable, CaseIterable {
        case high, medium, low

        var label: String {
            switch self {
            case .high:   return "高"
            case .medium: return "中"
            case .low:    return "低"
            }
        }
    }
}
