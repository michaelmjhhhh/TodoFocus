import SwiftUI

enum MotionTokens {
    static let quickDuration: Double = 0.14
    static let standardDuration: Double = 0.18
    static let emphasisDuration: Double = 0.26
    static let lingerDuration: Double = 0.22

    static let interactiveSpring = Animation.spring(response: 0.24, dampingFraction: 0.86)
    static let panelSpring = Animation.spring(response: 0.30, dampingFraction: 0.88)
    static let hoverEase = Animation.easeOut(duration: 0.14)
    static let focusEase = Animation.easeInOut(duration: 0.18)
    static let validationEase = Animation.easeInOut(duration: 0.20)
}
