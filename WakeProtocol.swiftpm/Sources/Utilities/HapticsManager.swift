import SwiftUI
import UIKit
import AudioToolbox

/// Centralized haptics and sound manager for Wake Protocol
final class HapticsManager {
    static let shared = HapticsManager()
    private init() {}

    // MARK: - Haptic Feedback

    /// Soft tap — used for UI interactions like button presses
    func lightTap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Medium impact — used for countdown ticks, phase changes
    func mediumTap() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Heavy impact — used for alarm critical phase
    func heavyTap() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Rigid impact — sharp, urgent feel for critical moments
    func rigidTap() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Success notification — used when challenge is completed
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    /// Error notification — used for wrong taps
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }

    /// Warning notification — used for phase transitions
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }

    // MARK: - System Sounds (work offline, no custom files needed)

    /// Short alert beep
    func playAlertSound() {
        AudioServicesPlaySystemSound(1005) // Short beep
    }

    /// Alarm-style sound
    func playAlarmSound() {
        AudioServicesPlaySystemSound(1304) // Alarm tone
    }

    /// Positive completion sound
    func playSuccessSound() {
        AudioServicesPlaySystemSound(1025) // Positive chime
    }

    /// Negative/error sound
    func playErrorSound() {
        AudioServicesPlaySystemSound(1073) // Error tone
    }

    /// Countdown tick sound
    func playTickSound() {
        AudioServicesPlaySystemSound(1103) // Tock sound
    }
}
