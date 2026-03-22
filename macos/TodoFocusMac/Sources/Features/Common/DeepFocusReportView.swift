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
                LabeledContent("Total distractions", value: "\(report.totalDistractionAttempts)")
                
                ForEach(report.distractionAttempts.sorted(by: { $0.value > $1.value }), id: \.key) { app, count in
                    LabeledContent(app, value: "\(count)")
                }
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
}