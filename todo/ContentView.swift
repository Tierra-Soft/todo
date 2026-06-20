import SwiftUI

// MARK: - Priority UI

extension TodoItem.Priority {
    var color: Color {
        switch self {
        case .high:   return .red
        case .medium: return .orange
        case .low:    return .blue
        }
    }
}

// MARK: - TodoRow

struct TodoRow: View {
    let item: TodoItem
    let onToggle: () -> Void
    let onDelete: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onToggle) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isCompleted ? Color.green : Color.secondary)
            }
            .buttonStyle(.plain)

            Circle()
                .fill(item.priority.color)
                .frame(width: 8, height: 8)

            Text(item.title)
                .strikethrough(item.isCompleted, color: .secondary)
                .foregroundStyle(item.isCompleted ? Color.secondary : Color.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if isHovered {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(Color.red.opacity(0.7))
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .contextMenu {
            Button(item.isCompleted ? "未完了に戻す" : "完了にする", action: onToggle)
            Divider()
            Button("削除", role: .destructive, action: onDelete)
        }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @StateObject private var store = TodoStore()
    @State private var newTitle = ""
    @State private var newPriority: TodoItem.Priority = .medium
    @State private var showCompleted = true
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            listArea
            Divider()
            inputBar
        }
        .frame(minWidth: 460, idealWidth: 520, minHeight: 400, idealHeight: 560)
    }

    // MARK: Header

    private var headerBar: some View {
        HStack(spacing: 8) {
            Text("TODO")
                .font(.title3.weight(.semibold))
            if store.pending.count > 0 {
                Text("\(store.pending.count)")
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.15), in: Capsule())
                    .foregroundStyle(Color.accentColor)
            }
            Spacer()
            Toggle(isOn: $showCompleted.animation()) {
                Label("完了を表示", systemImage: "checkmark.circle")
            }
            .toggleStyle(.checkbox)
            .help("完了済みタスクを表示/非表示")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: List

    @ViewBuilder
    private var listArea: some View {
        if store.items.isEmpty {
            emptyState
        } else {
            List {
                if !store.pending.isEmpty {
                    Section {
                        ForEach(store.pending) { item in
                            TodoRow(
                                item: item,
                                onToggle: { store.toggle(item) },
                                onDelete: { store.delete(item) }
                            )
                        }
                    } header: {
                        Text("未完了")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                if showCompleted && !store.completed.isEmpty {
                    Section {
                        ForEach(store.completed) { item in
                            TodoRow(
                                item: item,
                                onToggle: { store.toggle(item) },
                                onDelete: { store.delete(item) }
                            )
                        }
                    } header: {
                        Text("完了済み")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.inset)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "checklist")
                .font(.system(size: 44))
                .foregroundStyle(.quaternary)
            Text("タスクがありません")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("下のフィールドから新しいタスクを追加してください")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Input

    private var inputBar: some View {
        HStack(spacing: 8) {
            Picker("優先度", selection: $newPriority) {
                ForEach(TodoItem.Priority.allCases, id: \.self) { p in
                    Text(p.label).tag(p)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 90)
            .labelsHidden()
            .help("優先度を選択")

            TextField("新しいタスク...", text: $newTitle)
                .textFieldStyle(.roundedBorder)
                .focused($inputFocused)
                .onSubmit(addTodo)

            Button(action: addTodo) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(
                        newTitle.trimmingCharacters(in: .whitespaces).isEmpty
                            ? Color.secondary
                            : Color.accentColor
                    )
            }
            .buttonStyle(.plain)
            .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: Actions

    private func addTodo() {
        let title = newTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        store.add(title: title, priority: newPriority)
        newTitle = ""
        inputFocused = true
    }
}
