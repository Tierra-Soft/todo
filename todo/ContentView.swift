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

// MARK: - ProgressEditorView

struct ProgressEditorView: View {
    @Binding var progress: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("進捗")
                    .font(.headline)
                Spacer()
                Text("\(progress)%")
                    .font(.title2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Color.accentColor)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.1), value: progress)
            }

            Slider(value: Binding(
                get: { Double(progress) },
                set: { progress = Int($0) }
            ), in: 0...100, step: 5)

            HStack(spacing: 8) {
                ForEach([25, 50, 75, 100], id: \.self) { v in
                    Button("\(v)%") { progress = v }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(progress == v ? Color.accentColor : nil)
                }
                Spacer()
                Button("クリア") { progress = 0 }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
        }
        .padding(16)
        .frame(width: 260)
    }
}

// MARK: - TodoRow

struct TodoRow: View {
    let item: TodoItem
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onProgressChange: (Int) -> Void
    @State private var isHovered = false
    @State private var showProgressPopover = false

    private var isOverdue: Bool {
        guard let due = item.dueDate, !item.isCompleted else { return false }
        return due < Calendar.current.startOfDay(for: Date())
    }

    private func dueLabel(_ due: Date) -> String {
        if Calendar.current.isDateInToday(due)    { return "今日" }
        if Calendar.current.isDateInTomorrow(due) { return "明日" }
        return due.formatted(.dateTime.month().day())
    }

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

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .strikethrough(item.isCompleted, color: .secondary)
                    .foregroundStyle(item.isCompleted ? Color.secondary : Color.primary)

                if let due = item.dueDate {
                    HStack(spacing: 3) {
                        Image(systemName: isOverdue ? "exclamationmark.circle" : "calendar")
                            .font(.caption2)
                        Text(dueLabel(due))
                            .font(.caption)
                    }
                    .foregroundStyle(isOverdue ? Color.red : Color.secondary)
                }

                if !item.isCompleted && item.progress > 0 {
                    Button {
                        showProgressPopover = true
                    } label: {
                        HStack(spacing: 5) {
                            Capsule()
                                .fill(Color.secondary.opacity(0.18))
                                .frame(height: 4)
                                .overlay(alignment: .leading) {
                                    GeometryReader { geo in
                                        Capsule()
                                            .fill(Color.accentColor.opacity(0.75))
                                            .frame(width: geo.size.width * CGFloat(item.progress) / 100)
                                    }
                                }
                            Text("\(item.progress)%")
                                .font(.caption2)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showProgressPopover) {
                        ProgressEditorView(
                            progress: Binding(
                                get: { item.progress },
                                set: { onProgressChange($0) }
                            )
                        )
                    }
                }
            }
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
        .padding(.vertical, item.dueDate != nil ? 4 : 3)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .contextMenu {
            Button(item.isCompleted ? "未完了に戻す" : "完了にする", action: onToggle)
            if !item.isCompleted {
                Button("進捗を設定...") { showProgressPopover = true }
            }
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
    @State private var newDueDate: Date? = nil
    @State private var showDatePicker = false
    @State private var showCompleted = true
    @State private var searchText = ""
    @State private var priorityFilter: TodoItem.Priority? = nil
    @FocusState private var inputFocused: Bool

    var isFiltering: Bool { !searchText.isEmpty || priorityFilter != nil }

    var filteredPending: [TodoItem] {
        store.pending.filter { item in
            (searchText.isEmpty || item.title.localizedCaseInsensitiveContains(searchText))
                && (priorityFilter == nil || item.priority == priorityFilter)
        }
    }

    var filteredCompleted: [TodoItem] {
        store.completed.filter { item in
            (searchText.isEmpty || item.title.localizedCaseInsensitiveContains(searchText))
                && (priorityFilter == nil || item.priority == priorityFilter)
        }
    }

    private var hasVisibleItems: Bool {
        !filteredPending.isEmpty || (showCompleted && !filteredCompleted.isEmpty)
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            searchAndFilterBar
            Divider()
            listArea
            Divider()
            if showDatePicker {
                datePickerBar
                Divider()
            }
            inputBar
        }
        .frame(minWidth: 460, idealWidth: 540, minHeight: 440, idealHeight: 600)
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

    // MARK: Search + Filter

    private var searchAndFilterBar: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.callout)
                TextField("検索...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 16)
            .padding(.top, 8)

            // Priority filter chips
            HStack(spacing: 6) {
                filterChip(nil, label: "すべて")
                ForEach(TodoItem.Priority.allCases, id: \.self) { p in
                    filterChip(p, label: p.label, color: p.color)
                }
                Spacer()
                if isFiltering {
                    let count = filteredPending.count + filteredCompleted.count
                    Text("\(count) 件")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }

    private func filterChip(_ priority: TodoItem.Priority?, label: String, color: Color = .secondary) -> some View {
        let selected = priorityFilter == priority
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                priorityFilter = selected && priority != nil ? nil : priority
            }
        } label: {
            HStack(spacing: 4) {
                if priority != nil {
                    Circle().fill(color).frame(width: 6, height: 6)
                }
                Text(label)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                selected ? color.opacity(0.18) : Color.secondary.opacity(0.1),
                in: Capsule()
            )
            .foregroundStyle(selected ? color : Color.secondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: List

    @ViewBuilder
    private var listArea: some View {
        if store.items.isEmpty {
            emptyState
        } else if !hasVisibleItems {
            noResultsState
        } else {
            List {
                if !filteredPending.isEmpty {
                    Section {
                        ForEach(filteredPending) { item in
                            TodoRow(
                                item: item,
                                onToggle: { store.toggle(item) },
                                onDelete: { store.delete(item) },
                                onProgressChange: { store.updateProgress(item, progress: $0) }
                            )
                        }
                        .onMove { source, dest in
                            guard !isFiltering else { return }
                            store.movePending(from: source, to: dest)
                        }
                    } header: {
                        HStack(spacing: 4) {
                            Text("未完了")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            if isFiltering {
                                Text("(\(filteredPending.count) 件表示)")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }

                if showCompleted && !filteredCompleted.isEmpty {
                    Section {
                        ForEach(filteredCompleted) { item in
                            TodoRow(
                                item: item,
                                onToggle: { store.toggle(item) },
                                onDelete: { store.delete(item) },
                                onProgressChange: { store.updateProgress(item, progress: $0) }
                            )
                        }
                        .onMove { source, dest in
                            guard !isFiltering else { return }
                            store.moveCompleted(from: source, to: dest)
                        }
                    } header: {
                        HStack(spacing: 4) {
                            Text("完了済み")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            if isFiltering {
                                Text("(\(filteredCompleted.count) 件表示)")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
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

    private var noResultsState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44))
                .foregroundStyle(.quaternary)
            Text("該当するタスクがありません")
                .font(.title3)
                .foregroundStyle(.secondary)
            Button("検索をクリア") {
                withAnimation { searchText = ""; priorityFilter = nil }
            }
            .foregroundStyle(Color.accentColor)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Date Picker Bar

    private var datePickerBar: some View {
        HStack {
            Text("期限日")
                .font(.callout)
                .foregroundStyle(.secondary)
            DatePicker(
                "",
                selection: Binding(
                    get: { newDueDate ?? Date() },
                    set: { newDueDate = $0 }
                ),
                displayedComponents: .date
            )
            .labelsHidden()
            Spacer()
            if newDueDate != nil {
                Button("クリア") {
                    newDueDate = nil
                }
                .foregroundStyle(.secondary)
                .font(.callout)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: Input Bar

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

            Button {
                withAnimation { showDatePicker.toggle() }
            } label: {
                Image(systemName: newDueDate != nil ? "calendar.badge.checkmark" : "calendar")
                    .font(.body)
                    .foregroundStyle(newDueDate != nil ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.plain)
            .help(newDueDate.map { "期限日: \($0.formatted(.dateTime.month().day()))" } ?? "期限日を設定")

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
        store.add(title: title, priority: newPriority, dueDate: newDueDate)
        newTitle = ""
        newDueDate = nil
        showDatePicker = false
        inputFocused = true
    }
}
