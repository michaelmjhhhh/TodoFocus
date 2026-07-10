extension KanbanProjectRecord {
    var project: KanbanProject {
        KanbanProject(id: id, name: name, color: color, goal: goal, createdAt: createdAt, updatedAt: updatedAt)
    }
}

extension KanbanCardLabelRecord {
    var label: KanbanCardLabel {
        KanbanCardLabel(id: id, cardID: cardId, name: name, sortOrder: sortOrder)
    }
}

extension KanbanChecklistItemRecord {
    var item: KanbanChecklistItem {
        KanbanChecklistItem(id: id, cardID: cardId, title: title, isCompleted: isCompleted, sortOrder: sortOrder)
    }
}

extension KanbanCardRecord {
    func card(
        labels: [KanbanCardLabelRecord],
        checklist: [KanbanChecklistItemRecord]
    ) -> (card: KanbanCard, usedFallback: Bool) {
        let decodedStatus = KanbanStatus.persisted(status)
        let decodedPriority = KanbanPriority.persisted(priority)
        return (
            KanbanCard(
                id: id,
                projectID: projectId,
                title: title,
                description: description,
                status: decodedStatus.value,
                priority: decodedPriority.value,
                dueDate: dueDate,
                sortOrder: sortOrder,
                isArchived: isArchived,
                labels: labels.sorted { $0.sortOrder < $1.sortOrder }.map(\.label),
                checklist: checklist.sorted { $0.sortOrder < $1.sortOrder }.map(\.item),
                createdAt: createdAt,
                updatedAt: updatedAt
            ),
            decodedStatus.usedFallback || decodedPriority.usedFallback
        )
    }
}
