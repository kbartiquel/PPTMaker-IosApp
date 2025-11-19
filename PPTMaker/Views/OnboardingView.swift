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

    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "sparkles",
            iconColor: Color(red: 59/255, green: 130/255, blue: 246/255),
            title: "AI-Powered Presentations",
            description: "Create professional PowerPoint presentations in seconds with the power of AI",
            exampleTopics: ["Climate Change", "Marketing Strategy", "Product Launch"]
        ),
        OnboardingPage(
            icon: "pencil.and.outline",
            iconColor: Color(red: 139/255, green: 92/255, blue: 246/255),
            title: "Edit & Customize",
            description: "Review and edit AI-generated outlines before creating your final presentation",
            exampleTopics: nil
        ),
        OnboardingPage(
            icon: "paintpalette.fill",
            iconColor: Color(red: 251/255, green: 146/255, blue: 60/255),
            title: "15 Beautiful Templates",
            description: "Choose from professionally designed templates for any occasion",
            exampleTopics: nil
        ),
        OnboardingPage(
            icon: "square.and.arrow.down.fill",
            iconColor: Color(red: 16/255, green: 185/255, blue: 129/255),
            title: "Download & Share",
            description: "Export your presentations as PowerPoint files ready to present anywhere",
            exampleTopics: nil
        )
    ]

    var body: some View {
        ZStack {
            // Dark background
            Color(red: 18/255, green: 18/255, blue: 24/255)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Page Content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
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
        .preferredColorScheme(.dark)
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
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(red: 59/255, green: 130/255, blue: 246/255))
                .cornerRadius(12)
        }
    }

    private func completeOnboarding() {
        HapticManager.shared.success()
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        isPresented = false
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let exampleTopics: [String]?
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(page.iconColor.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: page.icon)
                    .font(.system(size: 60))
                    .foregroundColor(page.iconColor)
            }
            .padding(.bottom, 8)

            // Title
            Text(page.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Description
            Text(page.description)
                .font(.system(size: 16))
                .foregroundColor(Color.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)

            // Example Topics
            if let topics = page.exampleTopics {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Try these topics:")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.6))
                        .padding(.leading, 4)

                    ForEach(topics, id: \.self) { topic in
                        HStack(spacing: 12) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color(red: 251/255, green: 191/255, blue: 36/255))

                            Text(topic)
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 28/255, green: 32/255, blue: 42/255))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
            }

            Spacer()
            Spacer()
        }
        .padding()
    }
}

// MARK: - Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(isPresented: .constant(true))
    }
}
