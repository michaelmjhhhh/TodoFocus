import SwiftUI

struct SidebarView: View {
    @Bindable var appModel: AppModel
    let lists: [TodoList]

    var body: some View {
        List(selection: selectionBinding) {
            Section("Smart Lists") {
                smartRow("My Day", selection: .myDay)
                smartRow("Important", selection: .important)
                smartRow("Planned", selection: .planned)
                smartRow("All Tasks", selection: .all)
            }

            Section("Lists") {
                ForEach(lists) { list in
                    smartRow(list.name, selection: .customList(list.id))
                }
            }
        }
        .listStyle(.sidebar)
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

    private func smartRow(_ title: String, selection: SidebarSelection) -> some View {
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

        return Text(title).tag(tag)
    }
}
