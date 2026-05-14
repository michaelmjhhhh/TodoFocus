import SwiftUI

struct DailyReviewPreviewView: View {
    @Bindable var service: DailyReviewPreviewService
    let store: TodoAppStore
    let onClose: () -> Void
    let onActivateApp: () -> Void
    
    @Environment(\.themeTokens) private var tokens
    
    var body: some View {
        let board = DailyReview.buildBoard(store.reviewTodos)
        let snapshot = DailyReviewPreviewSnapshot.shaped(from: board, maxRowsPerBucket: 4)
        let totalOpen = snapshot.openTasks.reduce(0) { $0 + $1.tasks.count }
        let totalCompleted = snapshot.completedTasks.reduce(0) { $0 + $1.tasks.count }
        
        VStack(spacing: 18) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if totalOpen == 0 && totalCompleted == 0 {
                        Text("No tasks for review.")
                            .font(TypographyTokens.bodyLarge)
                            .foregroundStyle(tokens.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    } else {
                        taskSection(title: "Open", subtitle: "What needs attention next", columns: snapshot.openTasks, isCompletedSection: false)

                        if totalCompleted > 0 {
                            Divider()
                                .overlay(tokens.sectionBorder.opacity(0.9))

                            taskSection(title: "Completed", subtitle: "Recently finished", columns: snapshot.completedTasks, isCompletedSection: true)
                        }
                    }
                    
                    if snapshot.isTruncated {
                        Text("...and more")
                            .font(TypographyTokens.caption)
                            .foregroundStyle(tokens.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(.top, 2)
            }
            
            footer
        }
        .padding(SpacingTokens.xl)
        .frame(width: 340, height: 430)
        .background(
            RoundedRectangle(cornerRadius: RadiusTokens.lg, style: .continuous)
                .fill(tokens.bgElevated)
        )
        .shadowFloat()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "calendar.day.timeline.left")
                    .foregroundStyle(tokens.accentTerracotta)
                    .font(TypographyTokens.headingLarge)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Daily Review")
                            .font(TypographyTokens.displaySmall)
                            .foregroundStyle(tokens.textPrimary)
                        Text("Preview")
                            .font(TypographyTokens.micro)
                            .foregroundStyle(tokens.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(tokens.bgFloating.opacity(0.82), in: Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(tokens.sectionBorder.opacity(0.9), lineWidth: 1)
                            }
                    }
                    Text("Global shortcut ⌘⇧U")
                        .font(TypographyTokens.caption)
                        .foregroundStyle(tokens.textTertiary)
                }
                Spacer()
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(tokens.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(tokens.bgSubtle, in: RoundedRectangle(cornerRadius: RadiusTokens.sm, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close preview")
            }

        }
    }

    @ViewBuilder
    private func taskSection(title: String, subtitle: String, columns: [DailyReviewPreviewSnapshot.PreviewTaskColumn], isCompletedSection: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(TypographyTokens.micro)
                    .textCase(.uppercase)
                    .tracking(1.5)
                    .foregroundStyle(tokens.textTertiary)
                Text(subtitle)
                    .font(TypographyTokens.micro)
                    .foregroundStyle(tokens.textTertiary.opacity(0.9))
            }

            ForEach(columns) { column in
                if !column.tasks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(column.bucket.title)
                            .font(TypographyTokens.caption)
                            .foregroundStyle(tokens.textSecondary)

                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(column.tasks.prefix(4)) { task in
                                taskRow(task, isCompletedSection: isCompletedSection)
                            }
                        }
                    }
                }
            }
        }
    }

    private func taskRow(_ task: Todo, isCompletedSection: Bool) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(isCompletedSection ? tokens.textTertiary.opacity(0.45) : tokens.accentTerracotta.opacity(0.92))
                .frame(width: 3, height: 24)

            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(isCompletedSection ? TypographyTokens.bodySmall : TypographyTokens.bodyLarge)
                    .foregroundStyle(isCompletedSection ? tokens.textTertiary : tokens.textPrimary)
                    .strikethrough(isCompletedSection)
                    .opacity(isCompletedSection ? 0.5 : 1)

                HStack(spacing: 6) {
                    dueChip(text: DailyReview.dueText(for: task.dueDate), bucket: DailyReview.dueBucket(for: task.dueDate))
                    if task.isMyDay {
                        dueChip(text: "My Day", bucket: .today, accent: true)
                    }
                    if task.isImportant && !isCompletedSection {
                        dueChip(text: "Important", bucket: .later, accent: true)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(tokens.bgFloating.opacity(isCompletedSection ? 0.24 : 0.38), in: RoundedRectangle(cornerRadius: RadiusTokens.md, style: .continuous))
    }

    private func dueChip(text: String, bucket: DailyReviewTimeBucket, accent: Bool = false) -> some View {
        Text(text)
            .font(TypographyTokens.micro)
            .foregroundStyle(accent ? tokens.textPrimary : tokens.textSecondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(chipBackground(for: bucket, accent: accent), in: Capsule())
            .overlay {
                Capsule()
                    .stroke((accent ? tokens.accentTerracotta.opacity(0.35) : tokens.sectionBorder.opacity(0.7)), lineWidth: 1)
            }
    }

    private func chipBackground(for bucket: DailyReviewTimeBucket, accent: Bool) -> Color {
        if accent {
            return tokens.accentTerracotta.opacity(0.72)
        }

        switch bucket {
        case .overdue:
            return tokens.danger.opacity(0.18)
        case .today:
            return tokens.warning.opacity(0.16)
        case .tomorrow:
            return tokens.bgFloating.opacity(0.92)
        case .later, .noDate:
            return tokens.bgFloating.opacity(0.78)
        }
    }

    private var footer: some View {
        Button {
            onActivateApp()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.forward.app")
                    .font(TypographyTokens.caption)
                Text("Open Daily Review")
                    .font(TypographyTokens.headingSmall)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.borderedProminent)
        .tint(tokens.accentTerracotta)
    }
}
