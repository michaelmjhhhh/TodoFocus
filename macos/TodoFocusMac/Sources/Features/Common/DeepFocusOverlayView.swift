import SwiftUI

struct DeepFocusOverlayView: View {
    let blockedAppName: String
    let attemptCount: Int
    let onDismiss: () -> Void
    let onEndFocus: () -> Void
    @Environment(\.themeTokens) private var tokens
    @State private var isBreathing = false

    var body: some View {
        VStack(spacing: SpacingTokens.xl) {
            Image(systemName: "flame.fill")
                .font(.system(size: 48))
                .foregroundColor(tokens.accentTerracotta)
                .opacity(isBreathing ? 0.6 : 1.0)
                .onAppear {
                    withAnimation(MotionTokens.breathe) {
                        isBreathing = true
                    }
                }

            Text("Deep Focus Active")
                .font(TypographyTokens.displaySmall)
                .foregroundStyle(tokens.textPrimary)

            Text("You tried to open \(blockedAppName)")
                .font(TypographyTokens.bodySmall)
                .foregroundColor(tokens.textSecondary)

            Text("Attempt #\(attemptCount)")
                .font(TypographyTokens.caption)
                .foregroundColor(tokens.textSecondary)
                .padding(.horizontal, SpacingTokens.md)
                .padding(.vertical, SpacingTokens.xs)
                .background(tokens.textSecondary.opacity(0.2))
                .clipShape(Capsule())

            HStack(spacing: SpacingTokens.lg) {
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
        .padding(SpacingTokens.xxl)
        .background(
            RoundedRectangle(cornerRadius: RadiusTokens.lg)
                .fill(tokens.bgElevated)
        )
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: RadiusTokens.lg))
        .shadowFloat()
        .frame(width: 300)
    }
}
