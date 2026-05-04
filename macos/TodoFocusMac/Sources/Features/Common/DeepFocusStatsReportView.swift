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
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Deep Focus Stats")
                .font(.headline)
            
            HStack(spacing: 24) {
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
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(tokens.accentTerracotta)
            Text(value)
                .font(.title.weight(.semibold))
                .foregroundStyle(tokens.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(tokens.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
