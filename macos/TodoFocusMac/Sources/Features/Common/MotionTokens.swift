import SwiftUI

enum MotionTokens {
    static let quickDuration: Double = 0.16
    static let standardDuration: Double = 0.22
    static let emphasisDuration: Double = 0.35
    static let lingerDuration: Double = 0.24

    static let interactiveSpring = Animation.spring(response: 0.32, dampingFraction: 0.78)
    static let panelSpring = Animation.spring(response: 0.40, dampingFraction: 0.80)
    static let hoverEase = Animation.easeOut(duration: 0.22)
    static let focusEase = Animation.easeInOut(duration: 0.22)
    static let validationEase = Animation.easeInOut(duration: 0.22)

    static let checkboxSpring = Animation.spring(response: 0.35, dampingFraction: 0.65)
    static let gentleAppear = Animation.easeOut(duration: 0.30)
    static let fadeOut = Animation.easeIn(duration: 0.20)
    static let breathe = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
}
