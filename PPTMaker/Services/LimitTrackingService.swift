//
//  LimitTrackingService.swift
//  PPTMaker
//
//  Service for tracking user action limits (presentations and outlines)
//

import Foundation

/// Service for tracking presentation and outline generation limits
final class LimitTrackingService {
    static let shared = LimitTrackingService()

    private let userDefaults = UserDefaults.standard
    private let presentationCountKey = "presentation_generation_count"
    private let outlineCountKey = "outline_generation_count"

    private init() {}

    // MARK: - Public Methods

    /// Record that a presentation was generated
    func recordPresentationGeneration() {
        let count = getPresentationCount()
        userDefaults.set(count + 1, forKey: presentationCountKey)
        print("[LimitTracking] Presentation count: \(count + 1)")
    }

    /// Record that an outline was generated
    func recordOutlineGeneration() {
        let count = getOutlineCount()
        userDefaults.set(count + 1, forKey: outlineCountKey)
        print("[LimitTracking] Outline count: \(count + 1)")
    }

    /// Get current presentation generation count
    func getPresentationCount() -> Int {
        return userDefaults.integer(forKey: presentationCountKey)
    }

    /// Get current outline generation count
    func getOutlineCount() -> Int {
        return userDefaults.integer(forKey: outlineCountKey)
    }

    /// Check if presentation limit has been reached (premium users bypass limits)
    func hasReachedPresentationLimit() async -> Bool {
        // Check premium access first
        let hasPremium = await RevenueCatService.shared.hasPremiumAccess()
        if hasPremium {
            return false // Premium users have no limits
        }

        let count = getPresentationCount()
        let settings = PaywallSettingsService.shared.getSettings()
        return count >= settings.presentationLimit
    }

    /// Check if outline limit has been reached (premium users bypass limits)
    func hasReachedOutlineLimit() async -> Bool {
        // Check premium access first
        let hasPremium = await RevenueCatService.shared.hasPremiumAccess()
        if hasPremium {
            return false // Premium users have no limits
        }

        let count = getOutlineCount()
        let settings = PaywallSettingsService.shared.getSettings()
        return count >= settings.outlineLimit
    }

    /// Check if any limit has been reached (premium users bypass limits)
    func hasReachedAnyLimit() async -> Bool {
        // Check premium access first
        let hasPremium = await RevenueCatService.shared.hasPremiumAccess()
        if hasPremium {
            return false // Premium users have no limits
        }

        let presentationLimit = await hasReachedPresentationLimit()
        let outlineLimit = await hasReachedOutlineLimit()
        return presentationLimit || outlineLimit
    }

    /// Get remaining presentations before limit
    func getRemainingPresentations() -> Int {
        let count = getPresentationCount()
        let settings = PaywallSettingsService.shared.getSettings()
        return max(0, settings.presentationLimit - count)
    }

    /// Get remaining outlines before limit
    func getRemainingOutlines() -> Int {
        let count = getOutlineCount()
        let settings = PaywallSettingsService.shared.getSettings()
        return max(0, settings.outlineLimit - count)
    }

    /// Reset all counts (for testing or after purchase)
    func resetAllCounts() {
        userDefaults.set(0, forKey: presentationCountKey)
        userDefaults.set(0, forKey: outlineCountKey)
        print("[LimitTracking] All counts reset")
    }

    /// Get a summary of current usage
    func getUsageSummary() -> (presentations: Int, outlines: Int, presentationLimit: Int, outlineLimit: Int) {
        let settings = PaywallSettingsService.shared.getSettings()
        return (
            presentations: getPresentationCount(),
            outlines: getOutlineCount(),
            presentationLimit: settings.presentationLimit,
            outlineLimit: settings.outlineLimit
        )
    }
}
