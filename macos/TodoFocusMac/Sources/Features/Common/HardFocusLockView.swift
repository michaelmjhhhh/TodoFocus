import SwiftUI

struct HardFocusLockView: View {
    @ObservedObject var sessionManager: HardFocusSessionManager
    @Environment(\.themeTokens) private var tokens
    @State private var passphrase = ""
    @State private var showUnlockPopover = false
    @State private var showEmergencyConfirmation = false
    @State private var errorMessage: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tokens.accentTerracotta)
                .padding(8)
                .background(tokens.accentTerracotta.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("Hard Focus Active")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tokens.textPrimary)
                TimelineView(.periodic(from: .now, by: 30)) { context in
                    Text(sessionSubtitle(at: context.date))
                        .font(.caption)
                        .foregroundStyle(tokens.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            Button("Unlock") {
                errorMessage = nil
                passphrase = ""
                showUnlockPopover = true
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(tokens.accentTerracotta, in: Capsule())
            .foregroundStyle(Color.white)
            .popover(isPresented: $showUnlockPopover, arrowEdge: .top) {
                unlockPopover
            }

            Button("Emergency") {
                showEmergencyConfirmation = true
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(tokens.bgFloating, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(tokens.danger.opacity(0.45), lineWidth: 1)
            )
            .foregroundStyle(tokens.danger)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(tokens.bgElevated, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(tokens.sectionBorder.opacity(0.9), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.22), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .confirmationDialog(
            "Emergency Escape",
            isPresented: $showEmergencyConfirmation,
            titleVisibility: .visible
        ) {
            Button("End Session", role: .destructive) {
                Task {
                    try? await sessionManager.emergencyEndSession()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This ends the focus session immediately and marks it as interrupted.")
        }
    }

    private func sessionSubtitle(at now: Date) -> String {
        guard let session = sessionManager.currentSession else {
            return "Blocking distracting apps"
        }

        let blockedCount = session.blockedAppsBundleIds.count
        let blockText = blockedCount == 1 ? "1 app blocked" : "\(blockedCount) apps blocked"

        if session.plannedEndTime == .distantFuture {
            return "\(blockText) - Infinite session"
        }

        let remaining = max(0, Int(session.plannedEndTime.timeIntervalSince(now)))
        let minutes = Int(ceil(Double(remaining) / 60.0))
        return "\(blockText) - \(minutes)m remaining"
    }

    private var unlockPopover: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Unlock Hard Focus")
                .font(.headline)
                .foregroundStyle(tokens.textPrimary)

            SecureField("Enter passphrase", text: $passphrase)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    submitUnlock()
                }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(tokens.danger)
            }

            HStack(spacing: 8) {
                Button("Cancel") {
                    showUnlockPopover = false
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(tokens.bgFloating, in: Capsule())

                Spacer(minLength: 0)

                Button("Unlock") {
                    submitUnlock()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(tokens.accentTerracotta, in: Capsule())
                .foregroundStyle(.white)
            }
        }
        .padding(14)
        .frame(width: 300)
        .background(tokens.panelBackground)
    }

    private func submitUnlock() {
        Task {
            do {
                try await sessionManager.endSession(passphrase: passphrase)
                showUnlockPopover = false
                errorMessage = nil
                passphrase = ""
            } catch HardFocusError.invalidPassphrase {
                errorMessage = "Incorrect passphrase"
                passphrase = ""
            } catch {
                errorMessage = "Failed to end session"
            }
        }
    }
}
