import SwiftUI

struct DeepFocusOverlayView: View {
    let blockedAppName: String
    let attemptCount: Int
    let onDismiss: () -> Void
    let onEndFocus: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "flame.fill")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "C46849"))
            
            Text("Deep Focus Active")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("You tried to open \(blockedAppName)")
                .foregroundColor(.secondary)
            
            Text("Attempt #\(attemptCount)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.2))
                .clipShape(Capsule())
            
            HStack(spacing: 16) {
                Button("End Focus") {
                    onEndFocus()
                }
                .buttonStyle(.bordered)
                
                Button("Dismiss") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "1C1C1E"))
                .shadow(radius: 20)
        )
        .frame(width: 300)
    }
}
