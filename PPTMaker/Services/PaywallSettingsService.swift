//
//  PaywallSettingsService.swift
//  PPTMaker
//
//  Service for fetching and caching paywall configuration from API
//

import Foundation

/// Paywall configuration settings
struct PaywallSettings: Codable {
    // Feature limits
    let presentationLimit: Int
    let outlineLimit: Int

    // Paywall behavior
    let hardPaywall: Bool
    let customPaywall: Bool
    let paywallCloseButtonDelay: Int
    let paywallCloseButtonDelayOnLimit: Int
    let showPaywallOnStart: Bool

    // Custom Paywall Plan Visibility
    let paywallMonthly: Bool
    let paywallWeekly: Bool
    let paywallHideTrial: Bool
    let paywallYearly: Bool

    enum CodingKeys: String, CodingKey {
        case presentationLimit
        case outlineLimit
        case hardPaywall
        case customPaywall
        case paywallCloseButtonDelay
        case paywallCloseButtonDelayOnLimit
        case showPaywallOnStart
        case paywallMonthly
        case paywallWeekly
        case paywallHideTrial
        case paywallYearly
    }
}

/// Response model for settings API
struct PaywallSettingsResponse: Codable {
    let status: String
    let settings: PaywallSettings
}

/// Service for managing paywall settings
final class PaywallSettingsService {
    static let shared = PaywallSettingsService()

    private let settingsURL = "https://ppt-maker-server.onrender.com/settings"
    private let userDefaults = UserDefaults.standard
    private let cacheKey = "cached_paywall_settings"

    private var currentSettings: PaywallSettings?

    private init() {}

    // MARK: - Public Methods

    /// Initialize settings by fetching from API or loading from cache
    func initialize() async {
        await fetchSettings()
    }

    /// Refresh settings from API
    func refreshSettings() async {
        await fetchSettings()
    }

    /// Get current settings (returns cached if available, otherwise default)
    func getSettings() -> PaywallSettings {
        if let settings = currentSettings {
            return settings
        }

        // Try to load from cache
        if let cached = loadFromCache() {
            currentSettings = cached
            return cached
        }

        // Return default settings
        return defaultSettings()
    }

    // MARK: - Private Methods

    private func fetchSettings() async {
        guard let url = URL(string: settingsURL) else {
            print("[PaywallSettings] Invalid URL")
            currentSettings = loadFromCache() ?? defaultSettings()
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("[PaywallSettings] Invalid response, using cache")
                currentSettings = loadFromCache() ?? defaultSettings()
                return
            }

            let settingsResponse = try JSONDecoder().decode(PaywallSettingsResponse.self, from: data)
            currentSettings = settingsResponse.settings

            // Save to cache
            saveToCache(settingsResponse.settings)

            print("[PaywallSettings] Settings fetched successfully")

        } catch {
            print("[PaywallSettings] Error fetching settings: \(error.localizedDescription)")
            currentSettings = loadFromCache() ?? defaultSettings()
        }
    }

    private func saveToCache(_ settings: PaywallSettings) {
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: cacheKey)
        }
    }

    private func loadFromCache() -> PaywallSettings? {
        guard let data = userDefaults.data(forKey: cacheKey) else {
            return nil
        }
        return try? JSONDecoder().decode(PaywallSettings.self, from: data)
    }

    private func defaultSettings() -> PaywallSettings {
        return PaywallSettings(
            presentationLimit: 10,
            outlineLimit: 2,
            hardPaywall: false,
            customPaywall: true,
            paywallCloseButtonDelay: 30,
            paywallCloseButtonDelayOnLimit: 35,
            showPaywallOnStart: true,
            paywallMonthly: false,
            paywallWeekly: true,
            paywallHideTrial: false,
            paywallYearly: false
        )
    }
}
