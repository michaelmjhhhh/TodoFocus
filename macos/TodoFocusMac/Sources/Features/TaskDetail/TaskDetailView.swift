import SwiftUI

struct TaskDetailView: View {
    let todo: Todo?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let todo {
                Text(todo.title)
                    .font(.headline)
                if let dueDate = todo.dueDate {
                    Text("Due \(dueDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !todo.notes.isEmpty {
                    Text(todo.notes)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Select a task")
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
