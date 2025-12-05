//
//  OnboardingView.swift
//  PPTMaker
//
//  First-launch onboarding tutorial
//

import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var showPaywall = false
    @AppStorage("isDarkMode") private var isDarkMode = false

    // Dynamic colors based on theme
    private var backgroundColor: Color {
        isDarkMode ? Color(red: 18/255, green: 18/255, blue: 24/255) : Color(red: 245/255, green: 245/255, blue: 250/255)
    }

    private var cardColor: Color {
        isDarkMode ? Color(red: 28/255, green: 32/255, blue: 42/255) : Color.white
    }

    private var textColor: Color {
        isDarkMode ? .white : Color(red: 30/255, green: 30/255, blue: 30/255)
    }

    private var secondaryTextColor: Color {
        isDarkMode ? Color.white.opacity(0.7) : Color.gray
    }

    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "wand.and.stars",
            iconColor: Color.brandLight,
            title: "Create Stunning Presentations in Seconds",
            description: "Just enter a topic and get a complete, professional presentation instantly",
            features: [
                Feature(icon: "brain", text: "Instant professional content", color: Color.brandLight),
                Feature(icon: "clock", text: "Ready in seconds", color: Color.brandPrimary),
                Feature(icon: "star.fill", text: "Professional quality", color: Color.brandPrimary)
            ],
            visualType: .animated
        ),
        OnboardingPage(
            icon: "slider.horizontal.3",
            iconColor: Color.brandPrimary,
            title: "Control Your Presentation Style",
            description: "Choose between Dynamic mode or customize which slide types to use",
            features: [
                Feature(icon: "sparkles", text: "Dynamic: Auto-picks the best mix", color: Color.brandPrimary),
                Feature(icon: "checkmark.circle", text: "Custom: You choose slide types", color: Color.brandPrimary),
                Feature(icon: "list.bullet", text: "Quotes, columns, sections & more", color: Color.brandPrimary)
            ],
            visualType: .slideTypes
        ),
        OnboardingPage(
            icon: "pencil.and.list.clipboard",
            iconColor: Color.brandPrimary,
            title: "Edit Every Detail",
            description: "Fine-tune your presentation before generating the final file",
            features: [
                Feature(icon: "text.cursor", text: "Edit titles and content", color: Color.brandPrimary),
                Feature(icon: "arrow.up.arrow.down", text: "Reorder slides", color: Color.brandPrimary),
                Feature(icon: "plus.circle", text: "Add or remove slides", color: Color.brandPrimary)
            ],
            visualType: .standard
        ),
        OnboardingPage(
            icon: "square.and.arrow.down.fill",
            iconColor: Color(red: 16/255, green: 185/255, blue: 129/255),
            title: "Export & Present Anywhere",
            description: "Download your presentation as a PowerPoint file ready to use",
            features: [
                Feature(icon: "doc.fill", text: ".pptx format", color: Color(red: 16/255, green: 185/255, blue: 129/255)),
                Feature(icon: "shareplay", text: "Share instantly", color: Color(red: 20/255, green: 184/255, blue: 166/255)),
                Feature(icon: "checkmark.seal.fill", text: "Fully editable in PowerPoint", color: Color(red: 34/255, green: 197/255, blue: 94/255))
            ],
            visualType: .standard
        )
    ]

    var body: some View {
        ZStack {
            // Dynamic background
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Page Content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(
                            page: pages[index],
                            textColor: textColor,
                            secondaryTextColor: secondaryTextColor,
                            cardColor: cardColor
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                // Bottom Button
                bottomButton
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .fullScreenCover(isPresented: $showPaywall, onDismiss: {
            // Dismiss onboarding when paywall is dismissed
            isPresented = false
        }) {
            PaywallView(isLimitTriggered: false, hardPaywall: false)
        }
    }

    private var bottomButton: some View {
        Button {
            HapticManager.shared.mediumTap()
            if currentPage < pages.count - 1 {
                withAnimation {
                    currentPage += 1
                }
            } else {
                completeOnboarding()
            }
        } label: {
            Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isDarkMode ? .white : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.brandPrimary)
                .cornerRadius(12)
        }
    }

    private func completeOnboarding() {
        HapticManager.shared.success()
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")

        let settings = PaywallSettingsService.shared.getSettings()

        // Only show paywall after onboarding if showPaywallOnStart is enabled
        if settings.showPaywallOnStart {
            Task {
                let hasPremium = await RevenueCatService.shared.hasPremiumAccess()

                await MainActor.run {
                    if !hasPremium {
                        // Show paywall immediately before dismissing onboarding
                        showPaywall = true
                    } else {
                        // Dismiss onboarding only if user has premium
                        isPresented = false
                    }
                }
            }
        } else {
            // Skip paywall, go directly to app
            isPresented = false
        }
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let features: [Feature]
    let visualType: VisualType

    enum VisualType {
        case standard
        case animated
        case slideTypes
    }
}

struct Feature {
    let icon: String
    let text: String
    let color: Color
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    let textColor: Color
    let secondaryTextColor: Color
    let cardColor: Color

    @State private var animateIcon = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 20)

            // Icon with gradient background
            ZStack {
                // Gradient circle background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                page.iconColor.opacity(0.3),
                                page.iconColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .blur(radius: 15)

                Circle()
                    .fill(page.iconColor.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: page.icon)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(page.iconColor)
                    .scaleEffect(animateIcon ? 1.0 : 0.8)
                    .opacity(animateIcon ? 1.0 : 0.5)
            }

            // Title
            Text(page.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, 32)

            // Description
            Text(page.description)
                .font(.system(size: 15))
                .foregroundColor(secondaryTextColor)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)

            // Features list
            VStack(spacing: 10) {
                ForEach(Array(page.features.enumerated()), id: \.offset) { index, feature in
                    FeatureRow(
                        feature: feature,
                        textColor: textColor,
                        cardColor: cardColor,
                        delay: Double(index) * 0.1
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

            // Visual element based on page type
            if page.visualType == .slideTypes {
                SlideTypeVisual()
                    .padding(.top, 8)
            }

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animateIcon = true
            }
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let feature: Feature
    let textColor: Color
    let cardColor: Color
    let delay: Double

    @State private var appear = false

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(feature.color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: feature.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(feature.color)
            }

            // Text
            Text(feature.text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(textColor)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardColor)
                .shadow(color: feature.color.opacity(0.1), radius: 6, x: 0, y: 3)
        )
        .opacity(appear ? 1 : 0)
        .offset(x: appear ? 0 : -20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                appear = true
            }
        }
    }
}

// MARK: - Slide Type Visual
struct SlideTypeVisual: View {
    var body: some View {
        HStack(spacing: 12) {
            SlideTypeBadge(icon: "list.bullet", label: "Content", color: Color.brandPrimary)
            SlideTypeBadge(icon: "quote.bubble", label: "Quote", color: Color.brandPrimary)
            SlideTypeBadge(icon: "rectangle.split.2x1", label: "Columns", color: Color(red: 16/255, green: 185/255, blue: 129/255))
        }
        .padding(.horizontal, 32)
    }
}

struct SlideTypeBadge: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(isPresented: .constant(true))
    }
}
