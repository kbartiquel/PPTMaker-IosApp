//
//  CustomPaywallV3View.swift
//  PPTMaker
//
//  Custom paywall screen V3 - Without free trial toggle
//

import SwiftUI
import Combine
import RevenueCat

struct CustomPaywallV3View: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PaywallV3ViewModel()

    let isLimitTriggered: Bool
    let hardPaywall: Bool

    init(isLimitTriggered: Bool = false, hardPaywall: Bool = false) {
        self.isLimitTriggered = isLimitTriggered
        self.hardPaywall = hardPaywall
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
            if !hardPaywall {
                VStack {
                    HStack {
                        Spacer()
                        if viewModel.canClose {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 20))
                                    .foregroundColor(.gray)
                                    .padding()
                            }
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
            let delay = isLimitTriggered ? settings.paywallCloseButtonDelayOnLimit : settings.paywallCloseButtonDelay
            viewModel.loadOffering(closeDelay: delay)
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
                VStack(spacing: 20) {
                    // Ringing Icon Animation
                    Image("AppIconPaywall")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .cornerRadius(18)
                        .rotationEffect(.degrees(viewModel.iconRotation))
                        .padding(.top, 60)

                    // Title
                    Text("Premium Access")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)

                    // Features List
                    VStack(spacing: 12) {
                        featureRow(icon: "infinity", text: "Unlimited Presentations")
                        featureRow(icon: "bolt.fill", text: "Unlimited AI Outlines")
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
                if let lifetimePackage = viewModel.lifetimePackage {
                    planOption(
                        title: "Lifetime Plan",
                        price: lifetimePackage.storeProduct.localizedPriceString,
                        badge: "Best Value",
                        isSelected: viewModel.selectedPlan == "lifetime",
                        onTap: { viewModel.selectedPlan = "lifetime" }
                    )
                }

                // Monthly Package (conditionally shown)
                let settings = PaywallSettingsService.shared.getSettings()
                if let monthlyPackage = viewModel.monthlyPackage, settings.custompaywallv2Monthly {
                    planOption(
                        title: "Monthly Plan",
                        price: "\(monthlyPackage.storeProduct.localizedPriceString) per month",
                        isSelected: viewModel.selectedPlan == "monthly",
                        onTap: { viewModel.selectedPlan = "monthly" }
                    )
                }

                // Weekly Package (conditionally shown)
                if let weeklyPackage = viewModel.weeklyPackage, settings.custompaywallv2Weekly {
                    planOption(
                        title: "Weekly Plan",
                        price: "\(weeklyPackage.storeProduct.localizedPriceString) per week",
                        isSelected: viewModel.selectedPlan == "weekly",
                        onTap: { viewModel.selectedPlan = "weekly" }
                    )
                }

                Spacer().frame(height: 18)

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

                    Link("Privacy", destination: URL(string: "https://yourapp.com/privacy")!)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)

                    Text("•").font(.system(size: 12)).foregroundColor(.gray)

                    Link("Terms", destination: URL(string: "https://yourapp.com/terms")!)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
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
        price: String,
        badge: String? = nil,
        isSelected: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)

                    Text(price)
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                }

                Spacer()

                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red)
                        .cornerRadius(6)
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
            .padding()
            .background(isSelected ? Color.brandPrimary.opacity(0.1) : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.brandPrimary : Color.gray.opacity(0.3), lineWidth: 2)
            )
            .cornerRadius(12)
        }
    }
}

// MARK: - View Model
@MainActor
class PaywallV3ViewModel: ObservableObject {
    @Published var offering: Offering?
    @Published var lifetimePackage: Package?
    @Published var monthlyPackage: Package?
    @Published var weeklyPackage: Package?
    @Published var selectedPlan = "lifetime"
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

    func getButtonText() -> String {
        selectedPlan == "lifetime" ? "Get Lifetime Access" : "Subscribe Now"
    }

    func handlePurchase(onSuccess: @escaping () -> Void) {
        let package: Package?
        if selectedPlan == "lifetime" {
            package = lifetimePackage
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
                    // Success - dismiss paywall
                    onSuccess()
                }
            } catch {
                // Clear loading state on error/cancellation
                isPurchasing = false
                errorMessage = "Purchase failed: \(error.localizedDescription)"
                showError = true
            }
        }
    }

    func restorePurchases(onSuccess: @escaping () -> Void) {
        isRestoring = true

        Task {
            do {
                let customerInfo = try await Purchases.shared.restorePurchases()
                if !customerInfo.entitlements.active.isEmpty {
                    // Success - dismiss paywall
                    isRestoring = false
                    onSuccess()
                } else {
                    errorMessage = "No purchases to restore"
                    showError = true
                    isRestoring = false
                }
            } catch {
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
struct CustomPaywallV3View_Previews: PreviewProvider {
    static var previews: some View {
        CustomPaywallV3View(isLimitTriggered: false, hardPaywall: false)
    }
}
