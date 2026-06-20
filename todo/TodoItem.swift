import Foundation

struct TodoItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var isCompleted = false
    var priority: Priority = .medium
    var createdAt = Date()
    var dueDate: Date? = nil
    var progress: Int = 0  // 0–100

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

extension TodoItem {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(UUID.self,     forKey: .id)
        title       = try c.decode(String.self,   forKey: .title)
        isCompleted = try c.decode(Bool.self,     forKey: .isCompleted)
        priority    = try c.decode(Priority.self, forKey: .priority)
        createdAt   = try c.decode(Date.self,     forKey: .createdAt)
        dueDate     = try c.decodeIfPresent(Date.self, forKey: .dueDate)
        progress    = try c.decodeIfPresent(Int.self,  forKey: .progress) ?? 0
    }
}
