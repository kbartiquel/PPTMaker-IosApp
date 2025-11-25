//
//  CustomPaywallV1View.swift
//  PPTMaker
//
//  Custom paywall screen V1 - Classic design with trial support
//

import SwiftUI
import Combine
import RevenueCat

struct CustomPaywallV1View: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PaywallV1ViewModel()

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
                    // App Icon and Name
                    HStack(spacing: 12) {
                        Image("AppIconPaywall")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .cornerRadius(8)
                            .rotationEffect(.degrees(viewModel.iconRotation))

                        Text("PPT Maker")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    .padding(.top, 60)

                    // Title
                    if viewModel.hasIntroOffer {
                        Text("Try For Free")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                    }

                    Text(viewModel.hasIntroOffer ? "Start Your Free Trial" : "Unlock Premium Features")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)

                    // How Trial Works or Features
                    if viewModel.hasIntroOffer {
                        howTrialWorksView
                    } else {
                        featuresListView
                    }

                    // Pricing Info
                    if let package = viewModel.selectedPackage {
                        VStack(spacing: 10) {
                            if viewModel.hasIntroOffer {
                                Text("Unlimited access for free trial days")
                                    .font(.system(size: 16))
                                    .foregroundColor(.black)
                            }

                            HStack(spacing: 4) {
                                if viewModel.hasIntroOffer {
                                    Text("Then ")
                                        .font(.system(size: 16))
                                        .foregroundColor(.black)
                                }

                                Text(package.storeProduct.localizedPriceString)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black)

                                Text(viewModel.getPriceExtension(for: package))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black)
                            }

                            // Show monthly price for yearly plan
                            if package.storeProduct.subscriptionPeriod?.unit == .year {
                                if let monthlyPrice = viewModel.getMonthlyPrice(for: package) {
                                    Text("(\(monthlyPrice) per month)")
                                        .font(.system(size: 16))
                                        .foregroundColor(.black)
                                }
                            }

                            Button(action: { viewModel.showOtherPlans = true }) {
                                Text("View All Plans")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.brandPrimary)
                            }
                            .padding(.top, 5)
                        }
                    }

                    // Restore Button
                    Button(action: { viewModel.restorePurchases(onSuccess: { dismiss() }) }) {
                        VStack(spacing: 4) {
                            Text("Already subscribed?")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)

                            if viewModel.isRestoring {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Restore")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .disabled(viewModel.isRestoring)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
            }

            // Purchase Button
            VStack(spacing: 8) {
                Button(action: { viewModel.handlePurchase(onSuccess: { dismiss() }) }) {
                    VStack(spacing: 4) {
                        Text(viewModel.hasIntroOffer ? "Start Free Trial" : "Subscribe Now")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)

                        if viewModel.hasIntroOffer {
                            Text("Cancel Anytime")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.green)
                    .cornerRadius(12)
                }
                .disabled(viewModel.isPurchasing)
                .padding(.horizontal, 20)

                // Legal Links
                HStack(spacing: 8) {
                    Link("Privacy Policy", destination: URL(string: "https://yourapp.com/privacy")!)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)

                    Text("•")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)

                    Link("Terms & Conditions", destination: URL(string: "https://yourapp.com/terms")!)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 10)
            }
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
        }
        .sheet(isPresented: $viewModel.showOtherPlans) {
            if let offering = viewModel.offering {
                OtherPlansView(offering: offering, onPurchase: { package in
                    viewModel.showOtherPlans = false
                    viewModel.selectedPackage = package
                    viewModel.handlePurchase(onSuccess: { dismiss() })
                })
            }
        }
    }

    private var howTrialWorksView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Text("1")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.brandPrimary)
                    .frame(width: 32, height: 32)
                    .background(Color.brandPrimary.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Start Free Trial")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)

                    Text("Try all premium features for free")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }

            HStack(alignment: .top, spacing: 12) {
                Text("2")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.brandPrimary)
                    .frame(width: 32, height: 32)
                    .background(Color.brandPrimary.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Get Reminder")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)

                    Text("We'll remind you before trial ends")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }

            HStack(alignment: .top, spacing: 12) {
                Text("3")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.brandPrimary)
                    .frame(width: 32, height: 32)
                    .background(Color.brandPrimary.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Cancel Anytime")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)

                    Text("No charge if you cancel before trial ends")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.brandPrimary.opacity(0.05))
        .cornerRadius(12)
    }

    private var featuresListView: some View {
        VStack(spacing: 12) {
            PaywallFeatureRow(icon: "infinity", title: "Unlimited Presentations", description: "Create as many presentations as you want")
            PaywallFeatureRow(icon: "bolt.fill", title: "Unlimited Outlines", description: "Generate unlimited AI outlines")
            PaywallFeatureRow(icon: "paintbrush.fill", title: "All Templates", description: "Access to all premium templates")
            PaywallFeatureRow(icon: "star.fill", title: "Priority Support", description: "Get help faster when you need it")
        }
    }
}

// MARK: - Feature Row
struct PaywallFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.yellow)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.black)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Other Plans View
struct OtherPlansView: View {
    @Environment(\.dismiss) var dismiss
    let offering: Offering
    let onPurchase: (Package) -> Void
    @State private var selectedPackage: Package?

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                ForEach(offering.availablePackages, id: \.identifier) { package in
                    Button(action: {
                        selectedPackage = package
                        onPurchase(package)
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(getPackageTitle(package))
                                    .font(.headline)
                                    .foregroundColor(.black)

                                Text(getPackageDescription(package))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Text(package.storeProduct.localizedPriceString)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                        }
                        .padding()
                        .background(selectedPackage?.identifier == package.identifier ? Color.brandPrimary.opacity(0.1) : Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedPackage?.identifier == package.identifier ? Color.brandPrimary : Color.clear, lineWidth: 2)
                        )
                    }
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Choose Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func getPackageTitle(_ package: Package) -> String {
        if package.packageType == .lifetime {
            return "Lifetime Access"
        } else if package.storeProduct.subscriptionPeriod?.unit == .year {
            return "Yearly Plan"
        } else if package.storeProduct.subscriptionPeriod?.unit == .month {
            return "Monthly Plan"
        } else if package.storeProduct.subscriptionPeriod?.unit == .week {
            return "Weekly Plan"
        }
        return "Plan"
    }

    private func getPackageDescription(_ package: Package) -> String {
        if package.packageType == .lifetime {
            return "One-time payment"
        } else if package.storeProduct.introductoryDiscount != nil {
            return "Includes free trial"
        } else if let period = package.storeProduct.subscriptionPeriod {
            switch period.unit {
            case .day: return "Billed daily"
            case .week: return "Billed weekly"
            case .month: return "Billed monthly"
            case .year: return "Billed yearly"
            @unknown default: return "Subscription"
            }
        } else {
            return "Subscription"
        }
    }
}

// MARK: - View Model
@MainActor
class PaywallV1ViewModel: ObservableObject {
    @Published var offering: Offering?
    @Published var selectedPackage: Package?
    @Published var isLoading = true
    @Published var isPurchasing = false
    @Published var isRestoring = false
    @Published var canClose = false
    @Published var progress: CGFloat = 0
    @Published var showError = false
    @Published var showOtherPlans = false
    @Published var iconRotation: Double = 0
    var errorMessage = ""

    private var timer: Timer?
    private var secondsRemaining = 0
    private var totalSeconds = 0
    private var rotationTimer: Timer?

    var hasIntroOffer: Bool {
        selectedPackage?.storeProduct.introductoryDiscount != nil
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
                    self.selectedPackage = getDefaultPackage(from: current)
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

    private func getDefaultPackage(from offering: Offering) -> Package? {
        // Try to find yearly package with trial
        if let yearly = offering.availablePackages.first(where: { $0.storeProduct.subscriptionPeriod?.unit == .year && $0.storeProduct.introductoryDiscount != nil }) {
            return yearly
        }
        // Otherwise return first package
        return offering.availablePackages.first
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

    func handlePurchase(onSuccess: @escaping () -> Void) {
        guard let package = selectedPackage else { return }

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

    func getPriceExtension(for package: Package) -> String {
        guard let period = package.storeProduct.subscriptionPeriod else { return "" }

        switch period.unit {
        case .day: return " per day"
        case .week: return " per week"
        case .month: return " per month"
        case .year: return " per year"
        @unknown default: return ""
        }
    }

    func getMonthlyPrice(for package: Package) -> String? {
        guard let period = package.storeProduct.subscriptionPeriod,
              period.unit == .year else { return nil }

        let yearlyPrice = NSDecimalNumber(decimal: package.storeProduct.price)
        let monthlyPrice = yearlyPrice.dividing(by: NSDecimalNumber(value: 12))
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = package.storeProduct.priceFormatter?.locale

        return formatter.string(from: monthlyPrice)
    }

    deinit {
        timer?.invalidate()
        rotationTimer?.invalidate()
    }
}

// MARK: - Preview
struct CustomPaywallV1View_Previews: PreviewProvider {
    static var previews: some View {
        CustomPaywallV1View(isLimitTriggered: false, hardPaywall: false)
    }
}
