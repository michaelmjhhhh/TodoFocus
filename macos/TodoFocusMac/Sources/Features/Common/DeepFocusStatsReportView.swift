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
                    value: "\(stats.interruptionCount)",
                    label: "Interruptions"
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
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color(hex: "C46849"))
            Text(value)
                .font(.title.weight(.semibold))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
