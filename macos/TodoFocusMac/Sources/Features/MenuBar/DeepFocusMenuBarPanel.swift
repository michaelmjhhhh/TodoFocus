import SwiftUI
import AppKit

@MainActor
struct DeepFocusMenuBarPanel: View {
    @Bindable var store: TodoAppStore
    let mainWindowID: String

    @Environment(\.openWindow) private var openWindow
    @State private var themeTokens = ThemeTokens()
    @State private var now: Date = .now
    @State private var endFocusPassphrase: String = ""
    @State private var showEndFocusPrompt: Bool = false
    @State private var passphraseError: String?
    @FocusState private var isPassphraseFieldFocused: Bool

    var body: some View {
        let state = menuBarState(from: store, now: now)
        let blockedAppCount = store.deepFocusService.blockedApps.count

        VStack(alignment: .leading, spacing: 12) {
            statusSection(state: state)
            contextSection(state: state, blockedAppCount: blockedAppCount)

            Divider()
                .overlay(themeTokens.sectionBorder)

            VStack(spacing: 8) {
                MenuBarPanelActionButton(
                    title: "Open TodoFocus",
                    systemImage: "rectangle.inset.filled.and.person.filled",
                    isDestructive: false,
                    isDisabled: false
                ) {
                    openMainWindow()
                }

                MenuBarPanelActionButton(
                    title: "End Deep Focus",
                    systemImage: "stop.circle.fill",
                    isDestructive: true,
                    isDisabled: !state.isActive
                ) {
                    passphraseError = nil
                    showEndFocusPrompt.toggle()
                    if showEndFocusPrompt {
                        isPassphraseFieldFocused = true
                    }
                }

                MenuBarPanelActionButton(
                    title: "Quit",
                    systemImage: "power",
                    isDestructive: true,
                    isDisabled: false
                ) {
                    NSApplication.shared.terminate(nil)
                }
            }

            if showEndFocusPrompt && state.isActive {
                endFocusPrompt
            }
        }
        .padding(SpacingTokens.lg)
        .frame(width: 340)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: RadiusTokens.lg, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: RadiusTokens.lg, style: .continuous)
                    .fill(themeTokens.panelBackground.opacity(0.72))
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: RadiusTokens.lg))
        .shadowFloat()
        .animation(MotionTokens.panelSpring, value: state.isActive)
        .preferredColorScheme(.dark)
        .themeTokens(themeTokens)
        .onReceive(Timer.publish(every: 15, on: .main, in: .common).autoconnect()) { timestamp in
            now = timestamp
        }
        .onChange(of: state.isActive) { _, isActive in
            if !isActive {
                showEndFocusPrompt = false
                passphraseError = nil
                endFocusPassphrase = ""
            }
        }
    }

    @ViewBuilder
    private func statusSection(state: DeepFocusMenuBarState) -> some View {
        HStack(spacing: 10) {
            Image(systemName: state.isActive ? "flame.fill" : "flame")
                .font(TypographyTokens.headingSmall)
                .foregroundStyle(state.isActive ? themeTokens.accentTerracotta : themeTokens.textSecondary)
                .frame(width: 28, height: 28)
                .background(themeTokens.bgSubtle, in: RoundedRectangle(cornerRadius: RadiusTokens.sm))

            VStack(alignment: .leading, spacing: 2) {
                Text(state.title)
                    .font(TypographyTokens.bodyLarge)
                    .foregroundStyle(themeTokens.textPrimary)
                Text(state.subtitle)
                    .font(TypographyTokens.caption)
                    .foregroundStyle(themeTokens.textSecondary)
            }

            Spacer(minLength: 8)

            if let badge = state.menuBarBadge {
                Text(badge)
                    .font(TypographyTokens.caption.monospacedDigit())
                    .foregroundStyle(themeTokens.accentTerracotta)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(themeTokens.bgSubtle, in: Capsule())
            }
        }
    }

    @ViewBuilder
    private func contextSection(state: DeepFocusMenuBarState, blockedAppCount: Int) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                contextChip(title: "Blocked", value: "\(blockedAppCount) apps")
                contextChip(
                    title: "Session",
                    value: state.menuBarBadge.map { "\($0) left" } ?? (state.isActive ? "Running" : "Idle")
                )
            }

            if state.isActive, let title = currentFocusTaskTitle, !title.isEmpty {
                contextChip(title: "Task", value: title)
            }
        }
    }

    @ViewBuilder
    private func contextChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(TypographyTokens.micro)
                .foregroundStyle(themeTokens.textSecondary)
            Text(value)
                .font(TypographyTokens.caption)
                .foregroundStyle(themeTokens.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(themeTokens.bgSubtle, in: RoundedRectangle(cornerRadius: RadiusTokens.md))
    }

    @ViewBuilder
    private var endFocusPrompt: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Enter passphrase to end focus")
                .font(TypographyTokens.caption)
                .foregroundStyle(themeTokens.textPrimary)

            HStack(spacing: 8) {
                SecureField("Passphrase", text: $endFocusPassphrase)
                    .textFieldStyle(.plain)
                    .focused($isPassphraseFieldFocused)
                    .padding(.horizontal, 10)
                    .frame(height: 34)
                    .background(themeTokens.bgSubtle, in: RoundedRectangle(cornerRadius: RadiusTokens.sm))
                    .onSubmit {
                        submitEndFocus()
                    }

                Button("End") {
                    submitEndFocus()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
                .frame(height: 34)
                .background(themeTokens.accentTerracotta.opacity(0.22), in: RoundedRectangle(cornerRadius: RadiusTokens.sm))
                .foregroundStyle(themeTokens.textPrimary)
                .disabled(endFocusPassphrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if let passphraseError {
                Text(passphraseError)
                    .font(TypographyTokens.caption)
                    .foregroundStyle(themeTokens.danger)
            }
        }
        .padding(SpacingTokens.md)
        .background(themeTokens.bgSubtle, in: RoundedRectangle(cornerRadius: RadiusTokens.md))
        .shadowSubtle()
        .transition(.opacity.combined(with: .move(edge: .top)))
        .animation(MotionTokens.focusEase, value: passphraseError ?? "")
    }

    private var currentFocusTaskTitle: String? {
        guard let focusTaskId = store.deepFocusService.currentFocusTaskId else {
            return nil
        }
        return store.todos.first(where: { $0.id == focusTaskId })?.title
    }

    private func submitEndFocus() {
        let trimmed = endFocusPassphrase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }

        Task { @MainActor in
            do {
                _ = try await store.endDeepFocusWithPassphrase(trimmed)
                showEndFocusPrompt = false
                passphraseError = nil
                endFocusPassphrase = ""
            } catch let error as HardFocusError {
                if error == .invalidPassphrase {
                    passphraseError = "Invalid passphrase"
                } else {
                    passphraseError = "Unable to end focus right now"
                }
                isPassphraseFieldFocused = true
            } catch {
                passphraseError = "Unable to end focus right now"
                isPassphraseFieldFocused = true
            }
        }
    }

    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)

        if let existingWindow = NSApp.windows.first(where: { $0.canBecomeMain }) {
            if existingWindow.isMiniaturized {
                existingWindow.deminiaturize(nil)
            }
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }

        openWindow(id: mainWindowID)
    }
}

@MainActor
struct DeepFocusMenuBarLabel: View {
    @Bindable var store: TodoAppStore
    @State private var now: Date = .now

    init(store: TodoAppStore) {
        self._store = Bindable(store)
    }

    var body: some View {
        let state = menuBarState(from: store, now: now)

        HStack(spacing: 4) {
            Image(systemName: state.isActive ? "flame.fill" : "flame")
                .font(TypographyTokens.headingSmall)

            if let badge = state.menuBarBadge {
                Text(badge)
                    .font(TypographyTokens.caption.monospacedDigit())
                    .frame(minWidth: 28, alignment: .leading)
                    .transition(.opacity)
            }
        }
        .animation(MotionTokens.focusEase, value: state.menuBarBadge ?? "")
        .animation(MotionTokens.focusEase, value: state.isActive)
        .onReceive(Timer.publish(every: 15, on: .main, in: .common).autoconnect()) { timestamp in
            now = timestamp
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Deep Focus")
        .accessibilityValue(store.deepFocusService.isActive ? "Active" : "Not active")
    }
}

private struct MenuBarPanelActionButton: View {
    let title: String
    let systemImage: String
    let isDestructive: Bool
    let isDisabled: Bool
    let action: () -> Void

    @State private var isHovered: Bool = false
    @Environment(\.themeTokens) private var themeTokens

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(TypographyTokens.headingSmall)
                Text(title)
                    .font(TypographyTokens.headingSmall)
                Spacer(minLength: 0)
            }
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: RadiusTokens.md))
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.55 : 1)
        .onHover { hovering in
            isHovered = hovering
        }
        .animation(MotionTokens.hoverEase, value: isHovered)
        .animation(MotionTokens.focusEase, value: isDisabled)
        .accessibilityLabel(title)
    }

    private var foregroundColor: Color {
        if isDisabled {
            return themeTokens.textSecondary
        }
        return isDestructive ? themeTokens.danger : themeTokens.textPrimary
    }

    private var backgroundColor: Color {
        if isDisabled {
            return themeTokens.bgFloating.opacity(0.55)
        }
        if isHovered {
            return isDestructive ? themeTokens.danger.opacity(0.12) : themeTokens.bgFloating
        }
        return themeTokens.bgFloating.opacity(0.88)
    }

    private var borderColor: Color {
        if isHovered, !isDisabled {
            return isDestructive ? themeTokens.danger.opacity(0.62) : themeTokens.accentTerracotta.opacity(0.5)
        }
        return themeTokens.sectionBorder
    }
}

@MainActor
private func menuBarState(from store: TodoAppStore, now: Date) -> DeepFocusMenuBarState {
    DeepFocusMenuBarState.from(
        isActive: store.deepFocusService.isActive,
        sessionDuration: store.deepFocusService.sessionDuration,
        sessionStartedAt: store.deepFocusService.sessionStartedAt,
        now: now
    )
}
