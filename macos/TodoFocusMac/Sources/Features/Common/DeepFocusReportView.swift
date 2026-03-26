import SwiftUI

struct DeepFocusReportView: View {
    let report: DeepFocusReport
    let onDismiss: () -> Void
    @Environment(\.themeTokens) private var tokens

    @State private var isAppeared = false

    var body: some View {
        VStack(spacing: 24) {
            headerSection

            durationHero

            statsRow

            doneButton
        }
        .padding(28)
        .frame(width: 340)
        .background(tokens.bgFloating)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        .scaleEffect(isAppeared ? 1 : 0.9)
        .opacity(isAppeared ? 1 : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isAppeared)
        .onAppear {
            isAppeared = true
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(tokens.accentTerracotta.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(tokens.accentTerracotta)
            }

            Text("Focus Complete")
                .font(.title2.weight(.semibold))
                .foregroundStyle(tokens.textPrimary)
        }
    }

    private var durationHero: some View {
        VStack(spacing: 4) {
            Text(formatDuration(report.duration))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(tokens.textPrimary)
                .contentTransition(.numericText())

            Text("Duration")
                .font(.subheadline)
                .foregroundStyle(tokens.textSecondary)
        }
        .padding(.vertical, 8)
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(
                icon: "number.circle.fill",
                value: "\(report.stats.sessionCount)",
                label: "Sessions"
            )

            Divider()
                .frame(height: 40)
                .background(tokens.sectionBorder)

            statItem(
                icon: "bell.slash.fill",
                value: "\(report.distractionCount)",
                label: "Distractions"
            )
        }
        .padding(.vertical, 12)
        .background(tokens.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(tokens.accentTerracotta)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(tokens.textPrimary)

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(tokens.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var doneButton: some View {
        Button(action: onDismiss) {
            Text("Done")
                .font(.body.weight(.medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(tokens.accentTerracotta)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}
