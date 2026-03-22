import SwiftUI

struct SidebarView: View {
    @Bindable var appModel: AppModel
    @Bindable var store: TodoAppStore
    let lists: [TodoList]
    @State private var newListName: String = ""

    var body: some View {
        List {
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
                        .textFieldStyle(.plain)
                        .onSubmit(addList)
                        .foregroundStyle(VisualTokens.textPrimary)
                    Button(action: addList) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(AppIconButtonStyle(isEmphasized: true))
                    .foregroundStyle(VisualTokens.textPrimary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(VisualTokens.bgFloating, in: RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(VisualTokens.sectionBorder.opacity(0.9), lineWidth: 1)
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(VisualTokens.bgElevated)
        .animation(MotionTokens.focusEase, value: appModel.selection)
        .animation(MotionTokens.interactiveSpring, value: lists.count)
    }

    private func smartRow(_ title: String, systemImage: String, selection: SidebarSelection) -> some View {
        SidebarRowButton(
            title: title,
            systemImage: systemImage,
            isSelected: appModel.selection == selection,
            action: {
                withAnimation(MotionTokens.focusEase) {
                    appModel.selectSidebar(selection)
                }
            }
        )
    }

    private func addList() {
        let trimmed = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.createList(name: trimmed)
        newListName = ""
    }
}

private struct SidebarRowButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered: Bool = false

    private var rowBackground: Color {
        if isSelected {
            return VisualTokens.bgFloating
        }
        return isHovered ? VisualTokens.bgFloating.opacity(0.72) : Color.clear
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Capsule()
                    .fill(VisualTokens.accentBlue)
                    .frame(width: 3, height: 16)
                    .opacity(isSelected ? 1 : 0)

                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? VisualTokens.textPrimary : VisualTokens.textSecondary)

                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? VisualTokens.textPrimary : VisualTokens.textSecondary)

                Spacer(minLength: 0)

                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(VisualTokens.accentBlue)
                    .opacity(isSelected ? 1 : 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(rowBackground, in: RoundedRectangle(cornerRadius: 9))
            .overlay {
                RoundedRectangle(cornerRadius: 9)
                    .stroke(isSelected ? VisualTokens.accentBlue.opacity(0.55) : VisualTokens.sectionBorder.opacity(isHovered ? 0.55 : 0), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(SidebarRowButtonStyle())
        .onHover { hovering in
            withAnimation(MotionTokens.hoverEase) {
                isHovered = hovering
            }
        }
    }
}

private struct SidebarRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.986 : 1.0)
            .opacity(configuration.isPressed ? 0.95 : 1.0)
            .animation(MotionTokens.quickDuration == 0 ? .none : MotionTokens.hoverEase, value: configuration.isPressed)
    }
}
