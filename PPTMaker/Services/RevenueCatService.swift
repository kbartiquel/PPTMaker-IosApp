//
//  RevenueCatService.swift
//  PPTMaker
//
//  Service for managing RevenueCat subscription and entitlements
//

import Foundation
import UIKit
import RevenueCat
import RevenueCatUI

/// Service for managing RevenueCat subscriptions
final class RevenueCatService: NSObject {
    static let shared = RevenueCatService()

    // RevenueCat API key from RevenueCat dashboard
    // Get this from: https://app.revenuecat.com/settings/api-keys
    private let apiKey = "appl_GfdsBRLoPNeJWXaAIKcWWRSEbLF"

    private var isConfigured = false

    private override init() {}

    // MARK: - Initialization

    /// Configure RevenueCat on app launch
    func configure() {
        guard !isConfigured else { return }

        Purchases.logLevel = .debug // Change to .info in production
        Purchases.configure(withAPIKey: apiKey)

        // Set up customer info listener
        Purchases.shared.delegate = self

        isConfigured = true
        print("[RevenueCat] Configured successfully")
    }

    // MARK: - Entitlement Checking

    /// Check if user has active premium subscription
    func hasPremiumAccess() async -> Bool {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            let hasPremium = !customerInfo.entitlements.active.isEmpty
            print("[RevenueCat] Premium access: \(hasPremium)")
            return hasPremium
        } catch {
            print("[RevenueCat] Error checking entitlements: \(error.localizedDescription)")
            return false
        }
    }

    /// Check if specific entitlement is active
    func hasEntitlement(_ entitlementID: String) async -> Bool {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            let hasEntitlement = customerInfo.entitlements[entitlementID]?.isActive == true
            print("[RevenueCat] Entitlement '\(entitlementID)': \(hasEntitlement)")
            return hasEntitlement
        } catch {
            print("[RevenueCat] Error checking entitlement: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Paywall Presentation

    /// Present RevenueCat paywall
    @MainActor
    func presentPaywall() {
        Task {
            do {
                let paywallViewController = try await PaywallViewController()

                // Present the paywall
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    rootViewController.present(paywallViewController, animated: true)
                }
            } catch {
                print("[RevenueCat] Error presenting paywall: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Restore Purchases

    /// Restore previous purchases
    func restorePurchases() async -> Bool {
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            let hasActivePurchase = !customerInfo.entitlements.active.isEmpty
            print("[RevenueCat] Restore successful. Has active: \(hasActivePurchase)")
            return hasActivePurchase
        } catch {
            print("[RevenueCat] Restore failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Helper Methods

    /// Get customer info
    func getCustomerInfo() async -> String? {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            return customerInfo.originalAppUserId
        } catch {
            print("[RevenueCat] Error getting customer info: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - PurchasesDelegate

extension RevenueCatService: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        // Handle customer info updates
        let hasActivePurchase = !customerInfo.entitlements.active.isEmpty
        print("[RevenueCat] Customer info updated. Has active: \(hasActivePurchase)")

        // Post notification for UI updates
        NotificationCenter.default.post(
            name: NSNotification.Name("PremiumStatusChanged"),
            object: nil,
            userInfo: ["hasPremium": hasActivePurchase]
        )
    }
}
