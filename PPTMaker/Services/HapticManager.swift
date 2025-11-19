//
//  HapticManager.swift
//  PPTMaker
//
//  Manages haptic feedback throughout the app
//

import UIKit

class HapticManager {
    static let shared = HapticManager()

    private init() {}

    // MARK: - Impact Feedback
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    // MARK: - Notification Feedback
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    // MARK: - Selection Feedback
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    // MARK: - Convenience Methods
    func success() {
        notification(type: .success)
    }

    func error() {
        notification(type: .error)
    }

    func warning() {
        notification(type: .warning)
    }

    func lightTap() {
        impact(style: .light)
    }

    func mediumTap() {
        impact(style: .medium)
    }

    func heavyTap() {
        impact(style: .heavy)
    }
}
