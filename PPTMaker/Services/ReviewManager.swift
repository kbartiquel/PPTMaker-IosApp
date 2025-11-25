//
//  ReviewManager.swift
//  PPTMaker
//
//  Manages App Store review requests based on user milestones
//

import SwiftUI
import StoreKit

class ReviewManager {
    static let shared = ReviewManager()

    private init() {}

    // UserDefaults keys
    private let hasRequestedReviewKey = "hasRequestedReview"
    private let lastReviewRequestDateKey = "lastReviewRequestDate"
    private let presentationCountKey = "presentationCountForReview"
    private let reviewRequestCountKey = "reviewRequestCount"

    // MARK: - Review Request Logic

    /// Request review after successful purchase
    func requestReviewAfterPurchase() {
        guard shouldRequestReview() else { return }

        // Delay slightly to let purchase UI dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.performReviewRequest()
        }
    }

    /// Track presentation generation and request review after 4 presentations
    func trackPresentationGenerated() {
        var count = UserDefaults.standard.integer(forKey: presentationCountKey)
        count += 1
        UserDefaults.standard.set(count, forKey: presentationCountKey)

        // Request review after 4 presentations
        if count == 4 {
            requestReviewAfterMilestone()
        }
    }

    /// Request review after reaching presentation milestone
    private func requestReviewAfterMilestone() {
        guard shouldRequestReview() else { return }

        // Delay to let success UI show
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.performReviewRequest()
        }
    }

    // MARK: - Review Request Conditions

    private func shouldRequestReview() -> Bool {
        // Check if we've exceeded Apple's recommended limit (3 times per year)
        let requestCount = UserDefaults.standard.integer(forKey: reviewRequestCountKey)
        if requestCount >= 3 {
            // Check if a year has passed since last request
            if let lastRequestDate = UserDefaults.standard.object(forKey: lastReviewRequestDateKey) as? Date {
                let daysSinceLastRequest = Calendar.current.dateComponents([.day], from: lastRequestDate, to: Date()).day ?? 0
                if daysSinceLastRequest < 365 {
                    return false
                } else {
                    // Reset count after a year
                    UserDefaults.standard.set(0, forKey: reviewRequestCountKey)
                }
            }
        }

        // Don't request if we recently requested (within 60 days)
        if let lastRequestDate = UserDefaults.standard.object(forKey: lastReviewRequestDateKey) as? Date {
            let daysSinceLastRequest = Calendar.current.dateComponents([.day], from: lastRequestDate, to: Date()).day ?? 0
            if daysSinceLastRequest < 60 {
                return false
            }
        }

        return true
    }

    private func performReviewRequest() {
        #if os(iOS)
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            DispatchQueue.main.async {
                SKStoreReviewController.requestReview(in: scene)

                // Track that we requested a review
                UserDefaults.standard.set(Date(), forKey: self.lastReviewRequestDateKey)

                let currentCount = UserDefaults.standard.integer(forKey: self.reviewRequestCountKey)
                UserDefaults.standard.set(currentCount + 1, forKey: self.reviewRequestCountKey)
            }
        }
        #endif
    }

    // MARK: - Testing & Debug

    /// Force request review (for testing purposes)
    func forceRequestReview() {
        performReviewRequest()
    }

    /// Reset review tracking (for testing purposes)
    func resetReviewTracking() {
        UserDefaults.standard.removeObject(forKey: hasRequestedReviewKey)
        UserDefaults.standard.removeObject(forKey: lastReviewRequestDateKey)
        UserDefaults.standard.removeObject(forKey: presentationCountKey)
        UserDefaults.standard.removeObject(forKey: reviewRequestCountKey)
    }

    /// Get current presentation count
    func getPresentationCount() -> Int {
        return UserDefaults.standard.integer(forKey: presentationCountKey)
    }
}
