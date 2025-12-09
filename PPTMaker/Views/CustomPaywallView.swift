//
//  CustomPaywallView.swift
//  PPTMaker
//
//  Custom paywall screen with free trial toggle
//

import SwiftUI
import Combine
import RevenueCat

struct CustomPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PaywallViewModel()

    let isLimitTriggered: Bool
    let hardPaywall: Bool
    let showCloseButtonImmediately: Bool

    init(isLimitTriggered: Bool = false, hardPaywall: Bool = false, showCloseButtonImmediately: Bool = false) {
        self.isLimitTriggered = isLimitTriggered
        self.hardPaywall = hardPaywall
        self.showCloseButtonImmediately = showCloseButtonImmediately
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.brandPrimary))
            } else if viewModel.offering != nil {
                paywallContent
            }

            // Close button
            if !hardPaywall && !viewModel.isLoading{
                VStack {
                    HStack {
                        Spacer()
                        if viewModel.canClose {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 20))
                                    .foregroundColor(.gray)
                                    .frame(width: 32, height: 32)
                            }
                            .padding()
                        } else {
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                    .frame(width: 32, height: 32)

                                Circle()
                                    .trim(from: 0, to: viewModel.progress)
                                    .stroke(Color.gray, lineWidth: 2)
                                    .frame(width: 32, height: 32)
                                    .rotationEffect(.degrees(-90))
                            }
                            .padding()
                        }
                    }
                    Spacer()
                }
            }

            // Loading overlay
            if viewModel.isPurchasing {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
        .onAppear {
            let settings = PaywallSettingsService.shared.getSettings()
            // If showCloseButtonImmediately is true (e.g., credit badge tap), use 0 delay
            let delay = showCloseButtonImmediately ? 0 : (isLimitTriggered ? settings.paywallCloseButtonDelayOnLimit : settings.paywallCloseButtonDelay)
            viewModel.loadOffering(closeDelay: delay)

            // Track paywall shown
            let source = showCloseButtonImmediately ? "credit_badge" : (isLimitTriggered ? "limit_reached" : "app_launch")
            Task {
                let hasPremium = await RevenueCatService.shared.hasPremiumAccess()
                let outlineUsed = LimitTrackingService.shared.getOutlineCount()
                let presentationUsed = LimitTrackingService.shared.getPresentationCount()
                Analytics.shared.trackPaywallShown(
                    source: source,
                    hasPremium: hasPremium,
                    outlineCreditsUsed: outlineUsed,
                    outlineCreditsLimit: settings.outlineLimit,
                    presentationCreditsUsed: presentationUsed,
                    presentationCreditsLimit: settings.presentationLimit
                )
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    private var paywallContent: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    // Ringing Icon Animation
                    Image("AppIconPaywall")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .cornerRadius(18)
                        .rotationEffect(.degrees(viewModel.iconRotation))
                        .padding(.top, 30)

                    // Title
                    Text("Premium Access")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)

                    // Features List
                    VStack(spacing: 8) {
                        featureRow(icon: "infinity", text: "Unlimited Presentations")
                        featureRow(icon: "bolt.fill", text: "Unlimited Outlines")
                        featureRow(icon: "paintbrush.fill", text: "All Premium Templates")
                        featureRow(icon: "star.fill", text: "Priority Support")
                    }
                    .padding(.vertical, 10)
                }
                .padding(.horizontal, 20)
            }

            // Bottom Section with Plans
            VStack(spacing: 16) {
                // Plan Options
                let settings = PaywallSettingsService.shared.getSettings()
                let showYearly = settings.paywallYearly

                // Show Yearly Plan if setting enabled, otherwise show Lifetime
                if showYearly {
                    if let yearlyPackage = viewModel.yearlyPackage {
                        planOption(
                            title: "Yearly Plan",
                            subtitle: "Billed yearly, cancel anytime",
                            price: yearlyPackage.storeProduct.localizedPriceString,
                            badge: "Best Value",
                            isSelected: viewModel.selectedPlan == "yearly",
                            onTap: {
                                viewModel.selectedPlan = "yearly"
                                viewModel.trialEnabled = false
                            }
                        )
                    }
                } else {
                    if let lifetimePackage = viewModel.lifetimePackage {
                        planOption(
                            title: "Lifetime Plan",
                            subtitle: "Pay Once, Use Forever",
                            price: lifetimePackage.storeProduct.localizedPriceString,
                            badge: "Best Value",
                            isSelected: viewModel.selectedPlan == "lifetime",
                            onTap: {
                                viewModel.selectedPlan = "lifetime"
                                viewModel.trialEnabled = false
                            }
                        )
                    }
                }

                // Monthly Package (conditionally shown)
                if let monthlyPackage = viewModel.monthlyPackage, settings.paywallMonthly {
                    let hasMonthlyTrial = monthlyPackage.storeProduct.introductoryDiscount != nil
                    planOption(
                        title: hasMonthlyTrial ? "3-Day Free Trial" : "Monthly Plan",
                        subtitle: hasMonthlyTrial ? "Then \(monthlyPackage.storeProduct.localizedPriceString) per month" : "Billed monthly, cancel anytime",
                        price: hasMonthlyTrial ? "FREE" : monthlyPackage.storeProduct.localizedPriceString,
                        isSelected: viewModel.selectedPlan == "monthly",
                        onTap: {
                            viewModel.selectedPlan = "monthly"
                            if hasMonthlyTrial {
                                viewModel.trialEnabled = true
                            }
                        }
                    )
                }

                // Weekly Package (conditionally shown)
                if let weeklyPackage = viewModel.weeklyPackage, settings.paywallWeekly {
                    let hasWeeklyTrial = weeklyPackage.storeProduct.introductoryDiscount != nil
                    planOption(
                        title: hasWeeklyTrial ? "3-Day Free Trial" : "Weekly Plan",
                        subtitle: hasWeeklyTrial ? "Then \(weeklyPackage.storeProduct.localizedPriceString) per week" : "Billed weekly, cancel anytime",
                        price: hasWeeklyTrial ? "FREE" : weeklyPackage.storeProduct.localizedPriceString,
                        isSelected: viewModel.selectedPlan == "weekly",
                        onTap: {
                            viewModel.selectedPlan = "weekly"
                            if hasWeeklyTrial {
                                viewModel.trialEnabled = true
                            }
                        }
                    )
                }

                // Free Trial Toggle
                // - Hidden if only one package is shown and it has no trial
                // - Shown if there's at least one visible package with a trial
                if viewModel.shouldShowTrialToggle {
                    Toggle(isOn: $viewModel.trialEnabled) {
                        Text("Free Trial Enabled")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    .tint(Color.green)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .onChange(of: viewModel.trialEnabled) { newValue in
                        viewModel.handleTrialToggle(enabled: newValue)
                    }
                }

                // Purchase Button
                Button(action: { viewModel.handlePurchase(onSuccess: { dismiss() }) }) {
                    HStack {
                        Text(viewModel.getButtonText())
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)

                        Image(systemName: "arrow.right")
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.green)
                    .cornerRadius(4)
                }
                .disabled(viewModel.isPurchasing)

                // Footer Links
                HStack(spacing: 4) {
                    if viewModel.isRestoring {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                            .scaleEffect(0.7)
                    } else {
                        Button("Restore") { viewModel.restorePurchases(onSuccess: { dismiss() }) }
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }

                    Text("•").font(.system(size: 12)).foregroundColor(.gray)

                    Link("Privacy", destination: URL(string: "https://kimbytes.com/pptmaker/privacy.html")!)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)

                    Text("•").font(.system(size: 12)).foregroundColor(.gray)

                    Link("Terms", destination: URL(string: "https://kimbytes.com/pptmaker/terms.html")!)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 0)
            .background(Color.white)
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.brandPrimary.opacity(0.1))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.brandPrimary)
            }

            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
    }

    private func planOption(
        title: String,
        subtitle: String? = nil,
        price: String,
        badge: String? = nil,
        isSelected: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        let isFreePrice = price == "FREE"

        return Button(action: onTap) {
            HStack(spacing: 12) {
                // Left side: Title and subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                // Right side: Price and Radio button
                HStack(spacing: 8) {
                    if subtitle != nil {
                        Text(price)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isFreePrice ? .green : .black)
                    }

                    ZStack {
                        Circle()
                            .stroke(isSelected ? Color.brandPrimary : Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)

                        if isSelected {
                            Circle()
                                .fill(Color.brandPrimary)
                                .frame(width: 24, height: 24)

                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding()
            .background(isSelected ? Color.brandPrimary.opacity(0.1) : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.brandPrimary : Color.gray.opacity(0.3), lineWidth: 2)
            )
            .cornerRadius(12)
            .overlay(alignment: .topTrailing) {
                // Badge half-in half-out at top right
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(badge == "FREE" ? Color.green : Color.red)
                        .cornerRadius(4)
                        .offset(x: -12, y: -10)
                }
            }
        }
    }
}

// MARK: - View Model
@MainActor
class PaywallViewModel: ObservableObject {
    @Published var offering: Offering?
    @Published var lifetimePackage: Package?
    @Published var yearlyPackage: Package?
    @Published var monthlyPackage: Package?
    @Published var weeklyPackage: Package?
    @Published var selectedPlan: String = "lifetime" // Will be updated in loadOffering based on settings
    @Published var trialEnabled = false
    @Published var isLoading = true
    @Published var isPurchasing = false
    @Published var isRestoring = false
    @Published var canClose = false
    @Published var progress: CGFloat = 0
    @Published var showError = false
    @Published var iconRotation: Double = 0
    var errorMessage = ""

    private var timer: Timer?
    private var secondsRemaining = 0
    private var totalSeconds = 0
    private var rotationTimer: Timer?

    /// Returns true if at least one visible package has a trial
    var hasVisibleTrial: Bool {
        let settings = PaywallSettingsService.shared.getSettings()
        let monthlyHasTrial = monthlyPackage?.storeProduct.introductoryDiscount != nil && settings.paywallMonthly
        let weeklyHasTrial = weeklyPackage?.storeProduct.introductoryDiscount != nil && settings.paywallWeekly
        return monthlyHasTrial || weeklyHasTrial
    }

    /// Returns true if only one package (weekly or monthly) is shown
    var isOnlyOneSubscriptionShown: Bool {
        let settings = PaywallSettingsService.shared.getSettings()
        let monthlyShown = monthlyPackage != nil && settings.paywallMonthly
        let weeklyShown = weeklyPackage != nil && settings.paywallWeekly
        return (monthlyShown && !weeklyShown) || (!monthlyShown && weeklyShown)
    }

    /// Determines if the trial toggle should be shown
    /// - Hide toggle if only one package is shown and it has no trial
    /// - Show toggle if there's at least one visible package with a trial
    var shouldShowTrialToggle: Bool {
        let settings = PaywallSettingsService.shared.getSettings()

        // If only one subscription package is shown
        if isOnlyOneSubscriptionShown {
            // Check if that single package has a trial
            if settings.paywallMonthly && monthlyPackage != nil {
                return monthlyPackage?.storeProduct.introductoryDiscount != nil
            }
            if settings.paywallWeekly && weeklyPackage != nil {
                return weeklyPackage?.storeProduct.introductoryDiscount != nil
            }
            return false
        }

        // Both packages shown - show toggle if at least one has a trial
        return hasVisibleTrial
    }

    init() {
        startRingingAnimation()
    }

    func loadOffering(closeDelay: Int) {
        totalSeconds = closeDelay
        secondsRemaining = closeDelay
        canClose = closeDelay == 0

        Task {
            do {
                let offerings = try await Purchases.shared.offerings()
                if let current = offerings.current {
                    self.offering = current
                    findPackages(from: current)

                    // Set initial selected plan based on settings after packages are loaded
                    let settings = PaywallSettingsService.shared.getSettings()
                    if settings.paywallYearly && self.yearlyPackage != nil {
                        self.selectedPlan = "yearly"
                    } else if self.lifetimePackage != nil {
                        self.selectedPlan = "lifetime"
                    }

                    self.isLoading = false
                    startCloseTimer()
                } else {
                    self.isLoading = false
                    self.errorMessage = "No offerings available"
                    self.showError = true
                }
            } catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
    }

    private func findPackages(from offering: Offering) {
        // Find lifetime
        lifetimePackage = offering.availablePackages.first(where: { $0.packageType == .lifetime })

        // Find yearly
        yearlyPackage = offering.availablePackages.first(where: {
            $0.storeProduct.subscriptionPeriod?.unit == .year
        })

        // Find monthly
        monthlyPackage = offering.availablePackages.first(where: {
            $0.storeProduct.subscriptionPeriod?.unit == .month
        })

        // Find weekly
        weeklyPackage = offering.availablePackages.first(where: {
            $0.storeProduct.subscriptionPeriod?.unit == .week
        })
    }

    private func startCloseTimer() {
        guard totalSeconds > 0 else { return }

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                if self.secondsRemaining > 0 {
                    self.secondsRemaining -= 1
                    self.progress = CGFloat(self.totalSeconds - self.secondsRemaining) / CGFloat(self.totalSeconds)
                } else {
                    self.canClose = true
                    self.timer?.invalidate()
                }
            }
        }
    }

    private func startRingingAnimation() {
        rotationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.5)) {
                    if self.iconRotation == 0 {
                        self.iconRotation = 10
                    } else if self.iconRotation == 10 {
                        self.iconRotation = -10
                    } else {
                        self.iconRotation = 0
                    }
                }
            }
        }
    }

    func handleTrialToggle(enabled: Bool) {
        let settings = PaywallSettingsService.shared.getSettings()
        let weeklyHasTrial = weeklyPackage?.storeProduct.introductoryDiscount != nil && settings.paywallWeekly
        let monthlyHasTrial = monthlyPackage?.storeProduct.introductoryDiscount != nil && settings.paywallMonthly

        if enabled {
            // Enable trial - prioritize weekly if it has trial, otherwise monthly
            // This handles all cases:
            // - Both have trials: select weekly (priority)
            // - Only weekly has trial: select weekly
            // - Only monthly has trial: select monthly
            if weeklyHasTrial {
                selectedPlan = "weekly"
            } else if monthlyHasTrial {
                selectedPlan = "monthly"
            }
        } else {
            // Disable trial - select yearly if yearly mode enabled, otherwise lifetime
            if settings.paywallYearly {
                selectedPlan = "yearly"
            } else {
                selectedPlan = "lifetime"
            }
        }
    }

    func getButtonText() -> String {
        if selectedPlan == "lifetime" {
            return "Get Lifetime Access"
        } else if selectedPlan == "yearly" {
            return "Get Yearly Access"
        } else if trialEnabled && hasVisibleTrial {
            return "Try 3 Days Free"
        } else {
            return "Subscribe Now"
        }
    }

    func handlePurchase(onSuccess: @escaping () -> Void) {
        let package: Package?
        if selectedPlan == "lifetime" {
            package = lifetimePackage
        } else if selectedPlan == "yearly" {
            package = yearlyPackage
        } else if selectedPlan == "monthly" {
            package = monthlyPackage
        } else {
            package = weeklyPackage
        }

        guard let package = package else { return }

        isPurchasing = true

        Task {
            do {
                let result = try await Purchases.shared.purchase(package: package)
                // Always clear loading state
                isPurchasing = false

                if !result.customerInfo.entitlements.active.isEmpty {
                    // Success - track, request review and dismiss paywall
                    Analytics.shared.trackPurchaseCompleted(plan: selectedPlan)
                    ReviewManager.shared.requestReviewAfterPurchase()
                    onSuccess()
                }
            } catch {
                // Clear loading state on error/cancellation
                isPurchasing = false
                Analytics.shared.trackPurchaseFailed(plan: selectedPlan, error: error.localizedDescription)
                errorMessage = "Purchase failed: \(error.localizedDescription)"
                showError = true
            }
        }
    }

    func restorePurchases(onSuccess: @escaping () -> Void) {
        isRestoring = true
        Analytics.shared.trackRestorePurchasesTapped()

        Task {
            do {
                let customerInfo = try await Purchases.shared.restorePurchases()
                if !customerInfo.entitlements.active.isEmpty {
                    // Success - dismiss paywall
                    Analytics.shared.trackRestorePurchasesCompleted(success: true)
                    isRestoring = false
                    onSuccess()
                } else {
                    Analytics.shared.trackRestorePurchasesCompleted(success: false)
                    errorMessage = "No purchases to restore"
                    showError = true
                    isRestoring = false
                }
            } catch {
                Analytics.shared.trackRestorePurchasesCompleted(success: false)
                errorMessage = "Restore failed: \(error.localizedDescription)"
                showError = true
                isRestoring = false
            }
        }
    }

    deinit {
        timer?.invalidate()
        rotationTimer?.invalidate()
    }
}

// MARK: - Preview
struct CustomPaywallView_Previews: PreviewProvider {
    static var previews: some View {
        CustomPaywallView(isLimitTriggered: false, hardPaywall: false)
    }
}
