import SwiftUI
import AppKit

@MainActor
struct DeepFocusMenuBarPanel: View {
    @Bindable var store: TodoAppStore
    let themeStore: ThemeStore
    let mainWindowID: String

    @Environment(\.openWindow) private var openWindow
    @State private var themeTokens: ThemeTokens
    @State private var now: Date = .now

    init(store: TodoAppStore, themeStore: ThemeStore, mainWindowID: String) {
        self._store = Bindable(store)
        self.themeStore = themeStore
        self.mainWindowID = mainWindowID
        self._themeTokens = State(initialValue: ThemeTokens(theme: themeStore.theme))
    }

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
                    openWindow(id: mainWindowID)
                    NSApp.activate(ignoringOtherApps: true)
                }

                MenuBarPanelActionButton(
                    title: "End Deep Focus",
                    systemImage: "stop.circle.fill",
                    isDestructive: true,
                    isDisabled: !state.isActive
                ) {
                    Task { @MainActor in
                        _ = await store.endDeepFocus()
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
        }
        .padding(14)
        .frame(width: 320)
        .background(themeTokens.panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(themeTokens.sectionBorder, lineWidth: 1)
        }
        .shadow(color: themeTokens.textPrimary.opacity(0.18), radius: 10, y: 4)
        .animation(MotionTokens.panelSpring, value: state.isActive)
        .preferredColorScheme(themeStore.preferredColorScheme)
        .themeMode(themeStore.theme)
        .themeTokens(themeTokens)
        .onReceive(Timer.publish(every: 15, on: .main, in: .common).autoconnect()) { timestamp in
            now = timestamp
        }
        .onChange(of: themeStore.theme) { _, newTheme in
            themeTokens = ThemeTokens(theme: newTheme)
        }
    }

    @ViewBuilder
    private func statusSection(state: DeepFocusMenuBarState) -> some View {
        HStack(spacing: 10) {
            Image(systemName: state.isActive ? "flame.fill" : "flame")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(state.isActive ? themeTokens.accentTerracotta : themeTokens.textSecondary)
                .frame(width: 28, height: 28)
                .background(themeTokens.bgFloating, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(state.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(themeTokens.textPrimary)
                Text(state.subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(themeTokens.textSecondary)
            }

            Spacer(minLength: 8)

            if let badge = state.menuBarBadge {
                Text(badge)
                    .font(.system(size: 11, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(themeTokens.accentTerracotta)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(themeTokens.bgFloating, in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(themeTokens.sectionBorder, lineWidth: 1)
                    }
            }
        }
    }

    @ViewBuilder
    private func contextSection(state: DeepFocusMenuBarState, blockedAppCount: Int) -> some View {
        HStack(spacing: 8) {
            contextChip(title: "Blocked", value: "\(blockedAppCount) apps")
            contextChip(
                title: "Session",
                value: state.menuBarBadge.map { "\($0) left" } ?? (state.isActive ? "Running" : "Idle")
            )
        }
    }

    @ViewBuilder
    private func contextChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(themeTokens.textSecondary)
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(themeTokens.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(themeTokens.bgFloating, in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(themeTokens.sectionBorder, lineWidth: 1)
        }
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
                .font(.system(size: 13, weight: .semibold))

            if let badge = state.menuBarBadge {
                Text(badge)
                    .font(.system(size: 11, weight: .semibold, design: .rounded).monospacedDigit())
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
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Spacer(minLength: 0)
            }
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(borderColor, lineWidth: 1)
        }
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
