//
//  PaywallView.swift
//  PPTMaker
//
//  Paywall router - decides which paywall to show based on settings
//

import SwiftUI
import RevenueCat
import RevenueCatUI

struct PaywallView: View {
    let isLimitTriggered: Bool
    let hardPaywall: Bool
    let showCloseButtonImmediately: Bool

    init(isLimitTriggered: Bool = false, hardPaywall: Bool = false, showCloseButtonImmediately: Bool = false) {
        self.isLimitTriggered = isLimitTriggered
        self.hardPaywall = hardPaywall
        self.showCloseButtonImmediately = showCloseButtonImmediately
    }

    var body: some View {
        let settings = PaywallSettingsService.shared.getSettings()

        // Choose which paywall to show based on settings
        if settings.customPaywall {
            // Show custom paywall
            CustomPaywallView(
                isLimitTriggered: isLimitTriggered,
                hardPaywall: hardPaywall,
                showCloseButtonImmediately: showCloseButtonImmediately
            )
        } else {
            // Show RevenueCat dynamic paywall
            RevenueCatPaywallView(
                isLimitTriggered: isLimitTriggered,
                hardPaywall: hardPaywall
            )
        }
    }
}

// MARK: - RevenueCat Paywall View
struct RevenueCatPaywallView: View {
    @Environment(\.dismiss) var dismiss
    let isLimitTriggered: Bool
    let hardPaywall: Bool

    @State private var offering: Offering?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            if isLoading {
                // Show loading indicator while fetching offering
                ProgressView()
                    .scaleEffect(1.5)
            } else if let offering = offering {
                // Show paywall directly without nested sheet
                RevenueCatUI.PaywallView(offering: offering)
                    .onPurchaseCompleted { customerInfo in
                        if !customerInfo.entitlements.active.isEmpty {
                            dismiss()
                        }
                    }
                    .onRestoreCompleted { customerInfo in
                        if !customerInfo.entitlements.active.isEmpty {
                            dismiss()
                        }
                    }
                    .onRequestedDismissal {
                        // Handle when user taps X or cancels
                        dismiss()
                    }
            } else {
                // Error state
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    Text("Failed to load subscription options")
                        .font(.headline)
                    Button("Dismiss") {
                        dismiss()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
        .task {
            do {
                // Load offering
                let offerings = try await Purchases.shared.offerings()
                offering = offerings.current
                isLoading = false
            } catch {
                print("[RevenueCat] Error loading offering: \(error)")
                isLoading = false
            }
        }
    }
}

// MARK: - Preview
struct PaywallView_Previews: PreviewProvider {
    static var previews: some View {
        PaywallView(isLimitTriggered: true, hardPaywall: false)
    }
}
