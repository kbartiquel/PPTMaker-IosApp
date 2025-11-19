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
            iconColor: .blue,
            title: "AI-Powered Presentations",
            description: "Create professional PowerPoint presentations in seconds with the power of AI",
            exampleTopics: ["Climate Change", "Marketing Strategy", "Product Launch"]
        ),
        OnboardingPage(
            icon: "pencil.and.outline",
            iconColor: .purple,
            title: "Edit & Customize",
            description: "Review and edit AI-generated outlines before creating your final presentation",
            exampleTopics: nil
        ),
        OnboardingPage(
            icon: "paintpalette.fill",
            iconColor: .orange,
            title: "15 Beautiful Templates",
            description: "Choose from professionally designed templates for any occasion",
            exampleTopics: nil
        ),
        OnboardingPage(
            icon: "square.and.arrow.down.fill",
            iconColor: .green,
            title: "Download & Share",
            description: "Export your presentations as PowerPoint files ready to present anywhere",
            exampleTopics: nil
        )
    ]

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
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
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
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
            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundColor(page.iconColor)
                .padding(.bottom, 16)

            // Title
            Text(page.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Description
            Text(page.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Example Topics
            if let topics = page.exampleTopics {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Try these topics:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    ForEach(topics, id: \.self) { topic in
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text(topic)
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                }
                .padding(.top, 16)
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
