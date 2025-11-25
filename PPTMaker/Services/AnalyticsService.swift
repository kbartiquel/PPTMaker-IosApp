//
//  AnalyticsService.swift
//  PPTMaker
//
//  Analytics wrapper for Aptabase
//

import Foundation
import Aptabase

/// Analytics service for tracking user events
final class Analytics {
    static let shared = Analytics()

    private init() {}

    // MARK: - App Events

    func trackAppLaunched() {
        Aptabase.shared.trackEvent("app_launched")
    }

    // MARK: - Presentation Events

    func trackOutlineGenerated(topic: String, numSlides: Int, tone: String) {
        Aptabase.shared.trackEvent("outline_generated", with: [
            "num_slides": numSlides,
            "tone": tone
        ])
    }

    func trackOutlineGenerationFailed(error: String) {
        Aptabase.shared.trackEvent("outline_generation_failed", with: [
            "error": error
        ])
    }

    func trackPresentationGenerated(template: String, numSlides: Int) {
        Aptabase.shared.trackEvent("presentation_generated", with: [
            "template": template,
            "num_slides": numSlides
        ])
    }

    func trackPresentationGenerationFailed(error: String) {
        Aptabase.shared.trackEvent("presentation_generation_failed", with: [
            "error": error
        ])
    }

    // MARK: - Template Events

    func trackTemplateSelected(template: String) {
        Aptabase.shared.trackEvent("template_selected", with: [
            "template": template
        ])
    }

    // MARK: - Slide Events

    func trackSlideEdited() {
        Aptabase.shared.trackEvent("slide_edited")
    }

    func trackSlideRemoved() {
        Aptabase.shared.trackEvent("slide_removed")
    }

    // MARK: - History Events

    func trackHistoryViewed() {
        Aptabase.shared.trackEvent("history_viewed")
    }

    func trackPresentationShared() {
        Aptabase.shared.trackEvent("presentation_shared")
    }

    // MARK: - Onboarding Events

    func trackOnboardingCompleted() {
        Aptabase.shared.trackEvent("onboarding_completed")
    }

    func trackOnboardingSkipped() {
        Aptabase.shared.trackEvent("onboarding_skipped")
    }
}
