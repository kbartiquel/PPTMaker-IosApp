//
//  CreditInfoSheet.swift
//  PPTMaker
//
//  Shows credit usage info and upgrade option
//

import SwiftUI

struct CreditInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Binding var showPaywall: Bool

    let outlineUsageCount: Int
    let outlineLimit: Int
    let presentationUsageCount: Int
    let presentationLimit: Int

    private var isDarkMode: Bool {
        colorScheme == .dark
    }

    private var backgroundColor: Color {
        isDarkMode ? Color(red: 18/255, green: 18/255, blue: 24/255) : Color.white
    }

    private var cardColor: Color {
        isDarkMode ? Color(red: 28/255, green: 32/255, blue: 42/255) : Color(UIColor.secondarySystemBackground)
    }

    private var textColor: Color {
        isDarkMode ? .white : Color(red: 30/255, green: 30/255, blue: 30/255)
    }

    private var secondaryTextColor: Color {
        isDarkMode ? Color.white.opacity(0.6) : Color.gray
    }

    private var outlineRemaining: Int {
        max(0, outlineLimit - outlineUsageCount)
    }

    private var presentationRemaining: Int {
        max(0, presentationLimit - presentationUsageCount)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2.5)
                .fill(isDarkMode ? Color.white.opacity(0.3) : Color.gray.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 20)

            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.brandPrimary.opacity(0.2), Color.brandLight.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "sparkles")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.brandPrimary, Color.brandLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.bottom, 16)

            // Title
            Text("Free Credits")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(textColor)
                .padding(.bottom, 8)

            // Subtitle
            Text("You're using the free version of PPT Maker")
                .font(.system(size: 15))
                .foregroundColor(secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)

            // Credit Cards
            VStack(spacing: 12) {
                // Outline Credits Card
                creditCard(
                    icon: "wand.and.stars",
                    title: "AI Outlines",
                    used: outlineUsageCount,
                    total: outlineLimit,
                    remaining: outlineRemaining,
                    color: Color.brandPrimary
                )

                // Presentation Credits Card
                creditCard(
                    icon: "doc.richtext.fill",
                    title: "Presentations",
                    used: presentationUsageCount,
                    total: presentationLimit,
                    remaining: presentationRemaining,
                    color: Color(red: 16/255, green: 185/255, blue: 129/255)
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)

            // Unlock Button
            Button {
                HapticManager.shared.mediumTap()
                Analytics.shared.trackUnlockUnlimitedTapped(
                    outlineCreditsUsed: outlineUsageCount,
                    presentationCreditsUsed: presentationUsageCount
                )
                dismiss()
                // Small delay to let sheet dismiss before showing paywall
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showPaywall = true
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 18))
                    Text("Unlock Unlimited")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.brandPrimary, Color.brandLight],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: Color.brandPrimary.opacity(isDarkMode ? 0.5 : 0.4), radius: 10, x: 0, y: 5)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            // Dismiss text
            Button {
                HapticManager.shared.lightTap()
                dismiss()
            } label: {
                Text("Maybe Later")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(secondaryTextColor)
            }
            .padding(.bottom, 24)
        }
        .background(backgroundColor)
        .presentationDetents([.height(480)])
        .presentationDragIndicator(.hidden)
        .onAppear {
            Analytics.shared.trackCreditInfoSheetShown(
                outlineCreditsUsed: outlineUsageCount,
                outlineCreditsLimit: outlineLimit,
                presentationCreditsUsed: presentationUsageCount,
                presentationCreditsLimit: presentationLimit
            )
        }
    }

    private func creditCard(icon: String, title: String, used: Int, total: Int, remaining: Int, color: Color) -> some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(isDarkMode ? 0.2 : 0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(textColor)

                Text("\(remaining) remaining")
                    .font(.system(size: 13))
                    .foregroundColor(remaining > 0 ? secondaryTextColor : .red)
            }

            Spacer()

            // Usage badge
            Text("\(used)/\(total)")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(remaining > 0 ? color : .red)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(remaining > 0 ? color.opacity(isDarkMode ? 0.2 : 0.12) : Color.red.opacity(isDarkMode ? 0.2 : 0.12))
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardColor)
        )
    }
}

// MARK: - Preview
struct CreditInfoSheet_Previews: PreviewProvider {
    static var previews: some View {
        CreditInfoSheet(
            showPaywall: .constant(false),
            outlineUsageCount: 1,
            outlineLimit: 2,
            presentationUsageCount: 5,
            presentationLimit: 10
        )
    }
}
