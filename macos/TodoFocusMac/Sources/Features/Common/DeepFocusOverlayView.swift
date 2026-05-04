import SwiftUI

struct DeepFocusOverlayView: View {
    let blockedAppName: String
    let attemptCount: Int
    let onDismiss: () -> Void
    let onEndFocus: () -> Void
    @Environment(\.themeTokens) private var tokens

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "flame.fill")
                .font(.system(size: 48))
                .foregroundColor(tokens.accentTerracotta)

            Text("Deep Focus Active")
                .font(.system(.title2, design: .serif).weight(.regular))

            Text("You tried to open \(blockedAppName)")
                .foregroundColor(tokens.textSecondary)

            Text("Attempt #\(attemptCount)")
                .font(.caption)
                .foregroundColor(tokens.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(tokens.hairlineSoft)
                .clipShape(Capsule())

            HStack(spacing: 16) {
                Button("End Focus") {
                    onEndFocus()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(tokens.bgFloating, in: RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(tokens.hairline, lineWidth: 1)
                }
                .foregroundStyle(tokens.textPrimary)

                Button("Dismiss") {
                    onDismiss()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(tokens.accentTerracotta, in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.white)
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(tokens.bgElevated)
                .shadow(color: tokens.textPrimary.opacity(0.10), radius: 8)
        )
        .frame(width: 300)
    }
}
