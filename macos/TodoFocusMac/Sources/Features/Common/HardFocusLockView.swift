import SwiftUI

struct HardFocusLockView: View {
    @ObservedObject var sessionManager: HardFocusSessionManager
    @State private var passphrase = ""
    @State private var showEmergencyEscape = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("Hard Focus Active")
                .font(.title)
                .fontWeight(.bold)

            if let taskId = sessionManager.currentSession?.focusTaskId {
                Text("Focusing on task: \(taskId)")
                    .foregroundColor(.secondary)
            }

            Divider()

            VStack(spacing: 12) {
                SecureField("Enter passphrase to unlock", text: $passphrase)
                    .textFieldStyle(.roundedBorder)

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button("Unlock") {
                    Task {
                        do {
                            try await sessionManager.endSession(passphrase: passphrase)
                        } catch HardFocusError.invalidPassphrase {
                            errorMessage = "Incorrect passphrase"
                            passphrase = ""
                        } catch {
                            errorMessage = "Failed to end session"
                        }
                    }
                }
                .keyboardShortcut(.return)

                Button("Emergency Escape") {
                    showEmergencyEscape = true
                }
                .foregroundColor(.red)
            }

            Spacer()
        }
        .padding(40)
        .frame(minWidth: 400, minHeight: 300)
        .sheet(isPresented: $showEmergencyEscape) {
            EmergencyEscapeView(sessionManager: sessionManager)
        }
    }
}

struct EmergencyEscapeView: View {
    @ObservedObject var sessionManager: HardFocusSessionManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Emergency Escape")
                .font(.headline)

            Text("This will end the focus session immediately and mark it as interrupted. You will need to re-authenticate in System Preferences to use Hard Focus again.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button("Cancel", role: .cancel) {
                dismiss()
            }

            Button("End Session", role: .destructive) {
                Task {
                    try? await sessionManager.emergencyEndSession()
                    dismiss()
                }
            }
        }
        .padding()
        .frame(width: 400)
    }
}
