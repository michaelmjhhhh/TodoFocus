import SwiftUI

struct QuickCaptureView: View {
    @Bindable var service: QuickCaptureService
    let onSubmit: () -> Void
    let onCancel: () -> Void
    let targetInfo: String
    @Environment(\.themeTokens) private var tokens
    @State private var isSubmitting = false
    @State private var showSuccess = false

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(tokens.accentTerracotta)
                    .font(.system(size: 16, weight: .semibold))
                Text("Quick Capture")
                    .font(.headline)
                    .foregroundStyle(tokens.textPrimary)
                Spacer()
                Text(targetInfo)
                    .font(.caption)
                    .foregroundStyle(tokens.textSecondary)
            }

            HStack {
                TextField("Capture a thought...", text: $service.draftText)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(tokens.inputSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(tokens.inputBorder, lineWidth: 1)
                    )
                    .cornerRadius(8)
                    .foregroundStyle(tokens.textPrimary)
                    .scaleEffect(isSubmitting ? 0.98 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: isSubmitting)
                    .onSubmit {
                        handleSubmit()
                    }

                Button {
                    Task {
                        await service.toggleVoiceCapture()
                    }
                } label: {
                    Image(systemName: service.isRecordingVoice ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(service.isRecordingVoice ? tokens.danger : tokens.accentTerracotta)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(service.isRecordingVoice ? "Stop recording" : "Start recording")

                if showSuccess {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(tokens.success)
                        .font(.system(size: 20))
                        .transition(.scale.combined(with: .opacity))
                }
            }

            if let status = service.voiceStatusMessage {
                HStack(spacing: 6) {
                    Circle()
                        .fill(service.isRecordingVoice ? tokens.danger : tokens.textSecondary)
                        .frame(width: 6, height: 6)
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(tokens.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let error = service.voiceErrorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(tokens.warning)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(tokens.warning)
                    if service.needsVoicePermission {
                        Button("Open Settings") {
                            service.openVoicePermissionSettings()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.plain)
                .foregroundStyle(tokens.textSecondary)
                .keyboardShortcut(.escape)

                Button("Add") {
                    handleSubmit()
                }
                .buttonStyle(.borderedProminent)
                .tint(tokens.accentTerracotta)
                .keyboardShortcut(.return)
            }
        }
        .padding(16)
        .frame(width: 480, height: 220)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(tokens.bgElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(tokens.sectionBorder, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: showSuccess)
    }

    private func handleSubmit() {
        guard !service.draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            onCancel()
            return
        }
        isSubmitting = true
        onSubmit()
        withAnimation {
            showSuccess = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showSuccess = false
        }
    }
}

class QuickCaptureHostingView: NSHostingView<QuickCaptureView> {
    private let onSubmit: (String) -> Void
    private let onCancel: () -> Void

    required init(rootView: QuickCaptureView) {
        self.onSubmit = { _ in }
        self.onCancel = { }
        super.init(rootView: rootView)
    }

    init(service: QuickCaptureService, onSubmit: @escaping (String) -> Void, onCancel: @escaping () -> Void, targetInfo: String) {
        self.onSubmit = onSubmit
        self.onCancel = onCancel

        let view = QuickCaptureView(
            service: service,
            onSubmit: {
                onSubmit(service.draftText)
            },
            onCancel: onCancel,
            targetInfo: targetInfo
        )
        super.init(rootView: view)
    }
    
    @MainActor required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
