import SwiftUI

struct SidebarView: View {
    @Bindable var appModel: AppModel
    @Bindable var store: TodoAppStore
    let lists: [TodoList]
    @State private var newListName: String = ""

    var body: some View {
        List(selection: selectionBinding) {
            Section("Smart Lists") {
                smartRow("My Day", systemImage: "sun.max", selection: .myDay)
                smartRow("Important", systemImage: "star", selection: .important)
                smartRow("Planned", systemImage: "calendar", selection: .planned)
                smartRow("All Tasks", systemImage: "tray.full", selection: .all)
            }

            Section("Lists") {
                ForEach(lists) { list in
                    smartRow(list.name, systemImage: "circle.fill", selection: .customList(list.id))
                }

                HStack(spacing: 8) {
                    TextField("Add list", text: $newListName)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(addList)
                    Button(action: addList) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .listStyle(.sidebar)
        .animation(.easeInOut(duration: 0.18), value: appModel.selection)
        .animation(.spring(response: 0.25, dampingFraction: 0.86), value: lists.count)
    }

    private var selectionBinding: Binding<String?> {
        Binding(
            get: {
                switch appModel.selection {
                case .myDay:
                    return "smart:myday"
                case .important:
                    return "smart:important"
                case .planned:
                    return "smart:planned"
                case .all:
                    return "smart:all"
                case let .customList(id):
                    return "list:\(id)"
                }
            },
            set: { raw in
                guard let raw else { return }
                if raw == "smart:myday" {
                    appModel.selectSidebar(.myDay)
                } else if raw == "smart:important" {
                    appModel.selectSidebar(.important)
                } else if raw == "smart:planned" {
                    appModel.selectSidebar(.planned)
                } else if raw == "smart:all" {
                    appModel.selectSidebar(.all)
                } else if raw.hasPrefix("list:") {
                    appModel.selectSidebar(.customList(String(raw.dropFirst(5))))
                }
            }
        )
    }

    private func smartRow(_ title: String, systemImage: String, selection: SidebarSelection) -> some View {
        let tag: String
        switch selection {
        case .myDay:
            tag = "smart:myday"
        case .important:
            tag = "smart:important"
        case .planned:
            tag = "smart:planned"
        case .all:
            tag = "smart:all"
        case let .customList(id):
            tag = "list:\(id)"
        }

        return Label(title, systemImage: systemImage)
            .tag(tag)
    }

    private func addList() {
        let trimmed = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.createList(name: trimmed)
        newListName = ""
    }
}
