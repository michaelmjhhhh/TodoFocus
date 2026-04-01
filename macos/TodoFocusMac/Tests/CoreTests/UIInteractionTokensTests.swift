import XCTest
@testable import TodoFocusMac
import SwiftUI
import AppKit

final class UIInteractionTokensTests: XCTestCase {
    func testMotionDurationsStayInExpectedRanges() {
        XCTAssertTrue((0.12...0.20).contains(MotionTokens.quickDuration))
        XCTAssertTrue((0.16...0.24).contains(MotionTokens.standardDuration))
        XCTAssertTrue((0.22...0.32).contains(MotionTokens.emphasisDuration))
        XCTAssertTrue((0.18...0.28).contains(MotionTokens.lingerDuration))
    }

    func testVisualTokensExposeSemanticAccents() {
        _ = VisualTokens.violetAccent
        _ = VisualTokens.cyanAccent
        _ = VisualTokens.roseAccent
        _ = VisualTokens.accent
        XCTAssertTrue(true)
    }

    func testVisualTokensExposeSemanticPalette() {
        _ = VisualTokens.bgBase
        _ = VisualTokens.bgElevated
        _ = VisualTokens.bgFloating
        _ = VisualTokens.textPrimary
        _ = VisualTokens.textSecondary
        _ = VisualTokens.success
        _ = VisualTokens.warning
        _ = VisualTokens.danger
        _ = VisualTokens.accentBlue
        _ = VisualTokens.accentViolet
        _ = VisualTokens.accentAmber
        XCTAssertTrue(true)
    }

    func testVisualTokenBrightnessHierarchyStaysReadable() {
        let base = Self.relativeLuminance(for: VisualTokens.bgBase)
        let elevated = Self.relativeLuminance(for: VisualTokens.bgElevated)
        let floating = Self.relativeLuminance(for: VisualTokens.bgFloating)
        let textPrimary = Self.relativeLuminance(for: VisualTokens.textPrimary)
        let textSecondary = Self.relativeLuminance(for: VisualTokens.textSecondary)

        XCTAssertLessThan(base, elevated)
        XCTAssertLessThan(elevated, floating)
        XCTAssertGreaterThan(textPrimary, textSecondary)
        XCTAssertGreaterThan(textPrimary, floating)
    }

    func testStatusAndAccentTokensRemainDistinctFromNeutrals() {
        let neutral = Self.relativeLuminance(for: VisualTokens.bgElevated)
        let success = Self.relativeLuminance(for: VisualTokens.success)
        let warning = Self.relativeLuminance(for: VisualTokens.warning)
        let danger = Self.relativeLuminance(for: VisualTokens.danger)
        let accentBlue = Self.relativeLuminance(for: VisualTokens.accentBlue)

        XCTAssertGreaterThan(success, neutral)
        XCTAssertGreaterThan(warning, neutral)
        XCTAssertGreaterThan(danger, neutral)
        XCTAssertGreaterThan(accentBlue, neutral)
    }

    @MainActor
    func testRowSecondaryControlsStayVisibleForSelection() {
        XCTAssertTrue(TodoRowView.shouldShowSecondaryControls(isHovered: true, isSelected: false))
        XCTAssertTrue(TodoRowView.shouldShowSecondaryControls(isHovered: false, isSelected: true))
        XCTAssertFalse(TodoRowView.shouldShowSecondaryControls(isHovered: false, isSelected: false))
    }

    @MainActor
    func testLaunchpadHintCopyIsExplicitAndStable() {
        XCTAssertEqual(TaskDetailView.launchpadHintTitle, "Open everything in one action")
        XCTAssertEqual(TaskDetailView.launchpadHintSubtitle, "Add URL, file, or app resources, then choose Launch All.")
    }

    private static func relativeLuminance(for color: Color) -> CGFloat {
        let nsColor = NSColor(color).usingColorSpace(.deviceRGB) ?? NSColor(color)
        let linear = [nsColor.redComponent, nsColor.greenComponent, nsColor.blueComponent].map { channel in
            if channel <= 0.03928 {
                return channel / 12.92
            }
            return pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]
    }
}
