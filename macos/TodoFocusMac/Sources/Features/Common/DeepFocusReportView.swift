import SwiftUI

struct DeepFocusReportView: View {
    let report: DeepFocusReport
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 48))
                .foregroundColor(VisualTokens.accentTerracotta)
            
            Text("Focus Session Complete")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                LabeledContent("Duration", value: formatDuration(report.duration))
                LabeledContent("Distractions", value: "\(report.distractionCount)")
                LabeledContent("Total sessions", value: "\(report.stats.sessionCount)")
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Button("Done", action: onDismiss)
                .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .frame(width: 320)
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}