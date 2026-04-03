import AppKit
import Observation
import AVFoundation
import Speech

extension Notification.Name {
    static let todoFocusQuickAddFocusRequested = Notification.Name("todoFocusQuickAddFocusRequested")
}

@Observable
@MainActor
final class QuickCaptureService {
    private static let primaryLocaleID = "en-US"
    private static let silenceAutoFinalizeSeconds: TimeInterval = 1.6

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
    var voicePreviewText: String?

    var deepFocusService: DeepFocusService?
    var onCapture: ((String) -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var appDidBecomeActiveObserver: NSObjectProtocol?
    @ObservationIgnored private let audioEngine = AVAudioEngine()
    @ObservationIgnored private var recognitionRequests: [String: SFSpeechAudioBufferRecognitionRequest] = [:]
    @ObservationIgnored private var recognitionTasks: [String: SFSpeechRecognitionTask] = [:]
    @ObservationIgnored private var finalTranscriptsByLocale: [String: String] = [:]
    @ObservationIgnored private var partialTranscriptsByLocale: [String: String] = [:]
    @ObservationIgnored private var silenceAutoFinalizeWorkItem: DispatchWorkItem?
    @ObservationIgnored private var hasDetectedSpeechSinceRecordingStart: Bool = false
    @ObservationIgnored private var failedLocaleIDs: Set<String> = []
    @ObservationIgnored private var isCleaningUpHotkey: Bool = false

    func setup() {
        ensureLifecycleObservers()
        refreshAccessibilityAndHotkey()
    }

    private func refreshAccessibilityAndHotkey() {
        let trusted = AXIsProcessTrusted()
        needsAccessibilityPermission = !trusted
        if trusted {
            setupGlobalHotkey()
        } else {
            isHotkeyReady = false
        }
    }

    func requestAccessibilityPermission() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
        scheduleAccessibilityRecheck()
    }

    private func ensureLifecycleObservers() {
        if appDidBecomeActiveObserver == nil {
            appDidBecomeActiveObserver = NotificationCenter.default.addObserver(
                forName: NSApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.refreshAccessibilityAndHotkey()
            }
        }

    }

    private func scheduleAccessibilityRecheck(attemptsRemaining: Int = 6) {
        guard attemptsRemaining > 0 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self else { return }
            self.refreshAccessibilityAndHotkey()
            if self.needsAccessibilityPermission {
                self.scheduleAccessibilityRecheck(attemptsRemaining: attemptsRemaining - 1)
            }
        }
    }

    private func setupGlobalHotkey() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: true)
            isHotkeyReady = true
            return
        }

        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
            let service = Unmanaged<QuickCaptureService>.fromOpaque(refcon).takeUnretainedValue()

            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                DispatchQueue.main.async {
                    if let existingTap = service.eventTap {
                        CGEvent.tapEnable(tap: existingTap, enable: true)
                    }
                }
                return Unmanaged.passUnretained(event)
            }

            if type == .keyDown {
                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                let flags = event.flags

                let hasCmd = flags.contains(.maskCommand)
                let hasShift = flags.contains(.maskShift)
                let charsIgnoringModifiers = NSEvent(cgEvent: event)?.charactersIgnoringModifiers?.lowercased() ?? ""

                let isQuickCaptureKey = charsIgnoringModifiers == "t" || keyCode == 17

                if hasCmd && hasShift && isQuickCaptureKey {
                    DispatchQueue.main.async {
                        service.showCapturePanel()
                    }
                    return nil
                }

                let isQuickAddKey = charsIgnoringModifiers == "n" || keyCode == 45
                if hasCmd && hasShift && isQuickAddKey && NSApp.isActive {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .todoFocusQuickAddFocusRequested, object: nil)
                    }
                    return nil
                }
            }

            return Unmanaged.passUnretained(event)
        }

        let serviceRef = Unmanaged.passUnretained(self).toOpaque()
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: serviceRef
        ) else {
            isHotkeyReady = false
            return
        }

        guard let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0) else {
            CFMachPortInvalidate(eventTap)
            isHotkeyReady = false
            return
        }

        self.eventTap = eventTap
        self.runLoopSource = runLoopSource
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        isHotkeyReady = true
    }

    func showCapturePanel() {
        if panel == nil {
            panel = QuickCapturePanel()
        }

        draftText = ""
        voiceErrorMessage = nil
        voiceStatusMessage = nil
        needsVoicePermission = false
        voicePreviewText = nil

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
        voicePreviewText = nil
        finalTranscriptsByLocale = [:]
        partialTranscriptsByLocale = [:]
        hasDetectedSpeechSinceRecordingStart = false
        failedLocaleIDs = []
        cancelSilenceAutoFinalize()

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
            voiceStatusMessage = "Listening… English only"
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
        cancelSilenceAutoFinalize()

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        recognitionRequests.values.forEach { $0.endAudio() }

        let best = bestFinalTranscript()
        if !best.isEmpty {
            draftText = best
        } else if let preview = bestPartialPreview(), !preview.isEmpty {
            draftText = preview
        }

        teardownRecognitionPipeline(cancelTasks: true)
    }

    private func beginRecognitionPipeline() throws {
        teardownRecognitionPipeline(cancelTasks: true)

        let localeIDs = [Self.primaryLocaleID]

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
            let text = result.bestTranscription.formattedString.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                failedLocaleIDs.remove(localeID)
                hasDetectedSpeechSinceRecordingStart = true
                if result.isFinal {
                    finalTranscriptsByLocale[localeID] = text
                    partialTranscriptsByLocale[localeID] = nil
                    voicePreviewText = nil
                    let bestFinal = bestFinalTranscript()
                    if !bestFinal.isEmpty {
                        draftText = bestFinal
                    }
                } else {
                    partialTranscriptsByLocale[localeID] = text
                    voicePreviewText = bestPartialPreview()
                }
                scheduleSilenceAutoFinalize()
            }
        }

        if let _ = error, isRecordingVoice {
            failedLocaleIDs.insert(localeID)
            let laneCount = max(recognitionRequests.count, 1)
            let allRecognitionLanesFailed = failedLocaleIDs.count >= laneCount
            if allRecognitionLanesFailed && !hasDetectedSpeechSinceRecordingStart {
                voiceStatusMessage = "Listening interrupted, tap mic to retry"
            }
        }
    }

    private func bestFinalTranscript() -> String {
        for localeID in [Self.primaryLocaleID] {
            if let text = finalTranscriptsByLocale[localeID], !text.isEmpty {
                return text
            }
        }
        return finalTranscriptsByLocale.values.first(where: { !$0.isEmpty }) ?? ""
    }

    private func bestPartialPreview() -> String? {
        for localeID in [Self.primaryLocaleID] {
            if let text = partialTranscriptsByLocale[localeID], !text.isEmpty {
                return text
            }
        }
        return partialTranscriptsByLocale.values.first(where: { !$0.isEmpty })
    }

    private func scheduleSilenceAutoFinalize() {
        cancelSilenceAutoFinalize()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.isRecordingVoice else { return }
            self.stopVoiceCapture()
            self.voiceStatusMessage = "Auto-stopped after short silence"
        }
        silenceAutoFinalizeWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.silenceAutoFinalizeSeconds, execute: workItem)
    }

    private func cancelSilenceAutoFinalize() {
        silenceAutoFinalizeWorkItem?.cancel()
        silenceAutoFinalizeWorkItem = nil
    }

    private func teardownRecognitionPipeline(cancelTasks: Bool) {
        if cancelTasks {
            recognitionTasks.values.forEach { $0.cancel() }
        }
        recognitionTasks = [:]
        recognitionRequests = [:]
        finalTranscriptsByLocale = [:]
        partialTranscriptsByLocale = [:]
        hasDetectedSpeechSinceRecordingStart = false
        failedLocaleIDs = []
        voicePreviewText = nil
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
        if isCleaningUpHotkey {
            return
        }
        isCleaningUpHotkey = true
        defer { isCleaningUpHotkey = false }

        stopVoiceCapture()
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            CFRunLoopSourceInvalidate(runLoopSource)
        }
        if let eventTap = eventTap {
            CFMachPortInvalidate(eventTap)
        }
        if let observer = appDidBecomeActiveObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        appDidBecomeActiveObserver = nil
        eventTap = nil
        runLoopSource = nil
        isHotkeyReady = false
    }
}
