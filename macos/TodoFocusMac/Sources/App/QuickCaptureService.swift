import AppKit
import Observation
import AVFoundation
import Speech

@Observable
@MainActor
final class QuickCaptureService {
    var isVisible: Bool = false
    var needsAccessibilityPermission: Bool = false
    var isHotkeyReady: Bool = false
    private var panel: QuickCapturePanel?
    private var hostingView: QuickCaptureHostingView?

    var draftText: String = ""
    var isRecordingVoice: Bool = false
    var voiceStatusMessage: String?
    var voiceErrorMessage: String?
    var needsVoicePermission: Bool = false

    var deepFocusService: DeepFocusService?
    var onCapture: ((String) -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    @ObservationIgnored private let audioEngine = AVAudioEngine()
    @ObservationIgnored private var recognitionRequests: [String: SFSpeechAudioBufferRecognitionRequest] = [:]
    @ObservationIgnored private var recognitionTasks: [String: SFSpeechRecognitionTask] = [:]
    @ObservationIgnored private var transcriptsByLocale: [String: String] = [:]

    func setup() {
        checkAndRequestAccessibility()
        setupGlobalHotkey()
    }

    private func checkAndRequestAccessibility() {
        let trusted = AXIsProcessTrusted()
        if !trusted {
            needsAccessibilityPermission = true
        }
    }

    func requestAccessibilityPermission() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func setupGlobalHotkey() {
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
            let service = Unmanaged<QuickCaptureService>.fromOpaque(refcon).takeUnretainedValue()

            if type == .keyDown {
                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                let flags = event.flags

                let hasCmd = flags.contains(.maskCommand)
                let hasShift = flags.contains(.maskShift)

                if hasCmd && hasShift && keyCode == 17 {
                    Task { @MainActor in
                        service.showCapturePanel()
                    }
                    return nil
                }
            }

            return Unmanaged.passUnretained(event)
        }

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: eventMask, callback: callback, userInfo: selfPtr)

        guard let eventTap = eventTap else {
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    func showCapturePanel() {
        if panel == nil {
            panel = QuickCapturePanel()
        }

        draftText = ""
        voiceErrorMessage = nil
        voiceStatusMessage = nil
        needsVoicePermission = false

        let targetInfo: String
        if let dfService = deepFocusService, dfService.isActive {
            let count = dfService.blockedApps.count
            targetInfo = "Adding to Deep Focus (blocking \(count) apps)"
        } else {
            targetInfo = "No Deep Focus - will add to Inbox"
        }

        hostingView = QuickCaptureHostingView(
            service: self,
            onSubmit: { [weak self] text in
                self?.handleCapture(text)
            },
            onCancel: { [weak self] in
                self?.hidePanel()
            },
            targetInfo: targetInfo
        )

        panel?.contentView = hostingView
        panel?.showAtCenter()
        isVisible = true
    }

    func toggleVoiceCapture() async {
        if isRecordingVoice {
            stopVoiceCapture()
            return
        }
        await startVoiceCapture()
    }

    func openVoicePermissionSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_SpeechRecognition") {
            NSWorkspace.shared.open(url)
            return
        }
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }

    private func startVoiceCapture() async {
        if isRecordingVoice {
            return
        }

        voiceErrorMessage = nil
        voiceStatusMessage = nil
        transcriptsByLocale = [:]

        let granted = await ensureVoicePermissions()
        guard granted else {
            needsVoicePermission = true
            voiceErrorMessage = "Microphone and Speech Recognition permissions are required. You can still type manually."
            return
        }

        do {
            try beginRecognitionPipeline()
            isRecordingVoice = true
            needsVoicePermission = false
            voiceStatusMessage = "Listening… click again to stop"
        } catch {
            isRecordingVoice = false
            voiceStatusMessage = nil
            voiceErrorMessage = "Unable to start voice capture. Please try again."
            teardownRecognitionPipeline(cancelTasks: true)
        }
    }

    private func stopVoiceCapture() {
        if !isRecordingVoice && recognitionRequests.isEmpty {
            return
        }

        isRecordingVoice = false
        voiceStatusMessage = nil

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        recognitionRequests.values.forEach { $0.endAudio() }

        let best = bestTranscript()
        if !best.isEmpty {
            draftText = best
        }

        teardownRecognitionPipeline(cancelTasks: true)
    }

    private func beginRecognitionPipeline() throws {
        teardownRecognitionPipeline(cancelTasks: true)

        let localeIDs = ["en-US", "zh-CN"]

        for localeID in localeIDs {
            guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeID)),
                  recognizer.isAvailable else {
                continue
            }

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            recognitionRequests[localeID] = request

            recognitionTasks[localeID] = recognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    self?.handleRecognitionCallback(localeID: localeID, result: result, error: error)
                }
            }
        }

        if recognitionRequests.isEmpty {
            throw NSError(domain: "QuickCaptureService", code: 1)
        }

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        let activeRequests = Array(recognitionRequests.values)

        Self.installAudioTap(inputNode: inputNode, format: format, requests: activeRequests)

        audioEngine.prepare()
        try audioEngine.start()
    }

    private func handleRecognitionCallback(localeID: String, result: SFSpeechRecognitionResult?, error: Error?) {
        if let result {
            transcriptsByLocale[localeID] = result.bestTranscription.formattedString
            let best = bestTranscript()
            if !best.isEmpty {
                draftText = best
            }
        }

        if let _ = error, isRecordingVoice {
            let best = bestTranscript()
            if !best.isEmpty {
                draftText = best
            }
        }
    }

    private func bestTranscript() -> String {
        transcriptsByLocale.values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .max(by: { $0.count < $1.count }) ?? ""
    }

    private func teardownRecognitionPipeline(cancelTasks: Bool) {
        if cancelTasks {
            recognitionTasks.values.forEach { $0.cancel() }
        }
        recognitionTasks = [:]
        recognitionRequests = [:]
        transcriptsByLocale = [:]
    }

    private func ensureVoicePermissions() async -> Bool {
        let speechAuthorized = await ensureSpeechAuthorization()
        let microphoneAuthorized = await ensureMicrophoneAuthorization()
        return speechAuthorized && microphoneAuthorized
    }

    nonisolated private static func installAudioTap(
        inputNode: AVAudioInputNode,
        format: AVAudioFormat,
        requests: [SFSpeechAudioBufferRecognitionRequest]
    ) {
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            for request in requests {
                request.append(buffer)
            }
        }
    }

    nonisolated private func ensureSpeechAuthorization() async -> Bool {
        let status = SFSpeechRecognizer.authorizationStatus()
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { authStatus in
                    continuation.resume(returning: authStatus == .authorized)
                }
            }
        case .restricted, .denied:
            return false
        @unknown default:
            return false
        }
    }

    nonisolated private func ensureMicrophoneAuthorization() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    continuation.resume(returning: granted)
                }
            }
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    private func handleCapture(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            hidePanel()
            return
        }

        let timestamp = formatTimestamp(Date())
        let captureText = "\n[\(timestamp)] \(trimmed)"
        onCapture?(captureText)
        hidePanel()
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func hidePanel() {
        stopVoiceCapture()
        panel?.orderOut(nil)
        isVisible = false
    }

    func cleanup() {
        stopVoiceCapture()
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }
}
