import SwiftUI
import WidgetKit

struct DailyReviewWidgetView: View {
    let entry: DailyReviewWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        ZStack {
            background
            content
        }
        .containerBackground(for: .widget) {
            background
        }
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(WidgetTheme.surface)
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(WidgetTheme.border, lineWidth: 1)
            }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 10 : 12) {
            header
            metrics

            if entry.snapshot.items.isEmpty {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(entry.snapshot.items) { item in
                        itemRow(item)
                    }
                }
            }
        }
        .padding(family == .systemSmall ? 14 : 16)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 8) {
                Circle()
                    .fill(WidgetTheme.accent)
                    .frame(width: 8, height: 8)
                Text(entry.snapshot.title)
                    .font(.system(size: family == .systemSmall ? 15 : 17, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetTheme.textPrimary)
                Spacer(minLength: 0)
                Text(entry.snapshot.subtitle)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(WidgetTheme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(WidgetTheme.chip, in: Capsule())
            }

            Text("A compact view of what needs review next.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(WidgetTheme.textTertiary)
                .lineLimit(1)
        }
    }

    private var metrics: some View {
        HStack(spacing: 8) {
            ForEach(entry.snapshot.metrics) { metric in
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(metric.value)")
                        .font(.system(size: family == .systemSmall ? 16 : 18, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetTheme.textPrimary)
                    Text(metric.label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(WidgetTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .background(WidgetTheme.panel, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private func itemRow(_ item: DailyReviewWidgetSnapshot.Item) -> some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(item.bucket == .overdue ? WidgetTheme.accent : WidgetTheme.ruleMuted)
                .frame(width: 4, height: 34)

            VStack(alignment: .leading, spacing: 5) {
                Text(item.title)
                    .font(.system(size: family == .systemSmall ? 12 : 13, weight: .semibold))
                    .foregroundStyle(WidgetTheme.textPrimary)
                    .lineLimit(family == .systemSmall ? 1 : 2)

                HStack(spacing: 6) {
                    dueChip(text: item.dueLabel, bucket: item.bucket)
                    if item.isMyDay {
                        dueChip(text: "My Day", bucket: .today)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(WidgetTheme.row, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func dueChip(text: String, bucket: DailyReviewTimeBucket) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundStyle(bucket == .overdue ? WidgetTheme.textPrimary : WidgetTheme.textSecondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(chipBackground(for: bucket), in: Capsule())
    }

    private func chipBackground(for bucket: DailyReviewTimeBucket) -> Color {
        switch bucket {
        case .overdue:
            return WidgetTheme.accent.opacity(0.9)
        case .today:
            return WidgetTheme.panel.opacity(0.95)
        case .tomorrow, .later, .noDate:
            return WidgetTheme.chip
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.snapshot.emptyMessage ?? "No tasks to review")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(WidgetTheme.textPrimary)
            Text("Your Daily Review preview will appear here when open tasks exist.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(WidgetTheme.textSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.top, 4)
    }
}

private enum WidgetTheme {
    static let surface = Color(red: 0.11, green: 0.11, blue: 0.11)
    static let panel = Color(red: 0.15, green: 0.15, blue: 0.15)
    static let row = Color(red: 0.16, green: 0.16, blue: 0.16).opacity(0.96)
    static let chip = Color.white.opacity(0.06)
    static let border = Color.white.opacity(0.08)
    static let textPrimary = Color(red: 0.98, green: 0.98, blue: 0.98)
    static let textSecondary = Color(red: 0.55, green: 0.55, blue: 0.55)
    static let textTertiary = Color(red: 0.40, green: 0.40, blue: 0.40)
    static let accent = Color(red: 0.769, green: 0.408, blue: 0.286)
    static let ruleMuted = Color.white.opacity(0.18)
}
