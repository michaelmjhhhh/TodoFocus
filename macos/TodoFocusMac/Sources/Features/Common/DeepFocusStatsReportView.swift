import SwiftUI

struct DeepFocusStatsReportView: View {
    let stats: DeepFocusStats
    
    private var formattedTotalTime: String {
        let hours = Int(stats.totalFocusTime) / 3600
        let minutes = (Int(stats.totalFocusTime) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    @Environment(\.themeTokens) private var tokens

    var body: some View {
        VStack(spacing: SpacingTokens.lg) {
            Text("Deep Focus Stats")
                .font(TypographyTokens.headingLarge)
                .foregroundStyle(tokens.textPrimary)

            HStack(spacing: SpacingTokens.xl) {
                StatCard(
                    icon: "clock.fill",
                    value: formattedTotalTime,
                    label: "Total Time"
                )
                
                StatCard(
                    icon: "number.circle.fill",
                    value: "\(stats.sessionCount)",
                    label: "Sessions"
                )
                
                StatCard(
                    icon: "bell.slash.fill",
                    value: "\(stats.distractionCount)",
                    label: "Distractions"
                )
            }
        }
        .padding()
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    @Environment(\.themeTokens) private var tokens

    var body: some View {
        VStack(spacing: SpacingTokens.sm) {
            Image(systemName: icon)
                .font(TypographyTokens.displaySmall)
                .foregroundStyle(tokens.accentTerracotta)
            Text(value)
                .font(TypographyTokens.displaySmall.weight(.semibold))
                .foregroundStyle(tokens.textPrimary)
            Text(label)
                .font(TypographyTokens.caption)
                .foregroundStyle(tokens.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
