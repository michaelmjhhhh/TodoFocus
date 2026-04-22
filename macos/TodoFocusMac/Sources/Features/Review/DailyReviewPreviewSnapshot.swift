import Foundation

struct DailyReviewPreviewSnapshot {
    let openTasks: [PreviewTaskColumn]
    let completedTasks: [PreviewTaskColumn]
    let isTruncated: Bool

    struct PreviewTaskColumn: Identifiable {
        let bucket: DailyReviewTimeBucket
        let tasks: [Todo]
        var id: String { bucket.rawValue }
    }

    static func shaped(from board: DailyReviewBoard, maxRowsPerBucket: Int = 3) -> DailyReviewPreviewSnapshot {
        var truncated = false
        let openCols = board.openColumns.map { col -> PreviewTaskColumn in
            let prioritized = col.todos.sorted { lhs, rhs in
                if lhs.isMyDay && !rhs.isMyDay { return true }
                if !lhs.isMyDay && rhs.isMyDay { return false }
                if lhs.isImportant && !rhs.isImportant { return true }
                if !lhs.isImportant && rhs.isImportant { return false }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
            let capped = Array(prioritized.prefix(maxRowsPerBucket))
            if prioritized.count > maxRowsPerBucket { truncated = true }
            return PreviewTaskColumn(
                bucket: col.bucket,
                tasks: capped
            )
        }
        let completedCols = board.completedColumns.map { col -> PreviewTaskColumn in
            let capped = Array(col.todos.prefix(maxRowsPerBucket))
            if col.todos.count > maxRowsPerBucket { truncated = true }
            return PreviewTaskColumn(
                bucket: col.bucket,
                tasks: capped
            )
        }
        return DailyReviewPreviewSnapshot(openTasks: openCols, completedTasks: completedCols, isTruncated: truncated)
    }
}
