import Foundation

@MainActor
final class TodoStore: ObservableObject {
    @Published private(set) var items: [TodoItem] = []

    private let key = "todo.items"

    init() { load() }

    func add(title: String, priority: TodoItem.Priority, dueDate: Date? = nil) {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        var item = TodoItem(title: trimmed, priority: priority)
        item.dueDate = dueDate
        items.insert(item, at: 0)
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

    func movePending(from source: IndexSet, to destination: Int) {
        var ids = pending.map(\.id)
        ids.move(fromOffsets: source, toOffset: destination)
        reorder(ids: ids, positions: items.indices.filter { !items[$0].isCompleted })
    }

    func moveCompleted(from source: IndexSet, to destination: Int) {
        var ids = completed.map(\.id)
        ids.move(fromOffsets: source, toOffset: destination)
        reorder(ids: ids, positions: items.indices.filter { items[$0].isCompleted })
    }

    var pending: [TodoItem]   { items.filter { !$0.isCompleted } }
    var completed: [TodoItem] { items.filter {  $0.isCompleted } }

    private func reorder(ids: [UUID], positions: [Int]) {
        guard ids.count == positions.count else { return }
        let lookup = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        var newItems = items
        for (offset, pos) in positions.enumerated() {
            guard let item = lookup[ids[offset]] else { continue }
            newItems[pos] = item
        }
        items = newItems
        save()
    }

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
