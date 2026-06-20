import Foundation

@MainActor
final class TodoStore: ObservableObject {
    @Published private(set) var items: [TodoItem] = []

    private let key = "todo.items"

    init() { load() }

    func add(title: String, priority: TodoItem.Priority) {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        items.insert(TodoItem(title: trimmed, priority: priority), at: 0)
        save()
    }

    func toggle(_ item: TodoItem) {
        guard let i = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[i].isCompleted.toggle()
        save()
    }

    func delete(_ item: TodoItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    var pending: [TodoItem] { items.filter { !$0.isCompleted } }
    var completed: [TodoItem] { items.filter { $0.isCompleted } }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let saved = try? JSONDecoder().decode([TodoItem].self, from: data) else { return }
        items = saved
    }
}
