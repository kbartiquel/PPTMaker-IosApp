//
//  ContentView.swift
//  PPTMaker
//
//  Main view for the app - Two-step workflow
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PresentationViewModel()
    @State private var showTemplateSelection = false
    @State private var showHistory = false
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    @State private var justCompletedOnboarding = false
    @State private var previewURL: URL?
    @State private var showLaunchPaywall = false
    @State private var isCheckingPaywall = true
    @State private var showLimitBadgePaywall = false
    @State private var outlineUsageCount = 0
    @State private var hasPremiumAccess = false
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
        isDarkMode ? Color.white.opacity(0.6) : Color.gray
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Dynamic background with subtle gradient
                LinearGradient(
                    colors: [
                        backgroundColor,
                        isDarkMode ? Color(red: 22/255, green: 22/255, blue: 30/255) : Color(red: 240/255, green: 242/255, blue: 248/255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if isCheckingPaywall {
                    // Show loading while checking if paywall should be shown
                    ProgressView()
                        .scaleEffect(1.5)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Step 1: Topic Input
                            topicInputSection

                            // Step 2: Outline Generated - Edit and Template Selection
                            if viewModel.presentationOutline != nil {
                                outlineSection
                                templateSelectionSection
                                generateButtonSection
                            }
                        }
                        .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 60 : 20)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("PPT Maker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(isDarkMode ? .dark : .light, for: .navigationBar)
            .toolbarBackground(backgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        HapticManager.shared.selection()
                        withAnimation {
                            isDarkMode.toggle()
                        }
                    } label: {
                        Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                            .foregroundColor(isDarkMode ? .white : Color(red: 30/255, green: 30/255, blue: 30/255))
                    }
                }

                // Limit Badge - only shown for non-premium users
                if !hasPremiumAccess {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            HapticManager.shared.lightTap()
                            showLimitBadgePaywall = true
                        } label: {
                            limitBadgeView
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticManager.shared.lightTap()
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(isDarkMode ? .white : Color(red: 30/255, green: 30/255, blue: 30/255))
                    }
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .sheet(isPresented: $viewModel.showOutlineEditor) {
                OutlineEditorView(viewModel: viewModel)
            }
            .sheet(isPresented: $showTemplateSelection) {
                TemplateSelectionView(selectedTemplate: $viewModel.selectedTemplate)
            }
            .sheet(isPresented: $showHistory) {
                PresentationHistoryView(viewModel: viewModel)
            }
            .fullScreenCover(isPresented: $showOnboarding, onDismiss: {
                // Mark that we just completed onboarding to prevent double paywall
                justCompletedOnboarding = true
            }) {
                OnboardingView(isPresented: $showOnboarding)
            }
            .sheet(item: $previewURL) { url in
                QuickLookPreview(url: url)
            }
            .fullScreenCover(isPresented: $viewModel.showPaywall) {
                PaywallView(
                    isLimitTriggered: viewModel.isPaywallLimitTriggered,
                    hardPaywall: PaywallSettingsService.shared.getSettings().hardPaywall
                )
            }
            .fullScreenCover(isPresented: $showLaunchPaywall) {
                PaywallView(isLimitTriggered: false, hardPaywall: false)
            }
            .fullScreenCover(isPresented: $showLimitBadgePaywall) {
                PaywallView(isLimitTriggered: true, hardPaywall: false)
            }
            .onAppear {
                checkAndShowLaunchPaywall()
                updateLimitStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: .outlineGenerated)) { _ in
                updateLimitStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PremiumStatusChanged"))) { _ in
                updateLimitStatus()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    HapticManager.shared.error()
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .alert("Success!", isPresented: $viewModel.showSuccess) {
                Button("Preview") {
                    HapticManager.shared.lightTap()
                    if let url = viewModel.generatedFileURL {
                        // Dismiss alert first, then show preview after delay
                        viewModel.showSuccess = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            previewURL = url
                        }
                    }
                }
                Button("Share") {
                    HapticManager.shared.lightTap()
                    if let url = viewModel.generatedFileURL {
                        // Dismiss alert first, then share
                        viewModel.showSuccess = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            shareFile(url: url)
                        }
                    }
                }
                Button("Create Another") {
                    HapticManager.shared.mediumTap()
                    viewModel.resetAfterSuccess()
                }
                Button("Done", role: .cancel) {
                    HapticManager.shared.success()
                    viewModel.showSuccess = false
                }
            } message: {
                Text("Your presentation has been created successfully!")
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Step 1: Topic Input
    private var topicInputSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Topic Input Section
            VStack(alignment: .leading, spacing: 14) {
                // Section Header
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color.brandPrimary)

                    Text("Topic")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(textColor)
                }

                // Topic Input Card
                VStack(alignment: .leading, spacing: 10) {
                    Text("What's your presentation about?")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(secondaryTextColor)

                    TextField("", text: $viewModel.topic, prompt: Text("e.g., 'The Future of Renewable Energy'").foregroundColor(secondaryTextColor.opacity(0.6)))
                        .font(.system(size: 15))
                        .foregroundColor(textColor)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isDarkMode ? Color(red: 32/255, green: 36/255, blue: 48/255) : Color.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.brandPrimary.opacity(0.2), lineWidth: 1)
                        )
                        .disabled(viewModel.isGeneratingOutline)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(cardColor)
                        .shadow(color: Color.black.opacity(isDarkMode ? 0.3 : 0.08), radius: 12, x: 0, y: 4)
                )
            }

            // Number of Slides Section
            VStack(alignment: .leading, spacing: 14) {
                // Section Header
                HStack(spacing: 8) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 15))
                        .foregroundColor(Color.brandPrimary)

                    Text("Slides")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(textColor)
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Number of slides")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(secondaryTextColor)

                        Spacer()

                        Text("\(viewModel.numSlides)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color.brandPrimary)
                    }

                    HStack(spacing: 10) {
                        Text("5")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(secondaryTextColor)

                        Slider(value: Binding(
                            get: { Double(viewModel.numSlides) },
                            set: { viewModel.numSlides = Int($0) }
                        ), in: 5...20, step: 1)
                        .accentColor(Color.brandPrimary)
                        .disabled(viewModel.isGeneratingOutline)

                        Text("20")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(secondaryTextColor)
                    }

                    // Warning for 15+ slides
                    if viewModel.numSlides >= 15 {
                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .font(.system(size: 11))
                            Text("May take 30-60 seconds to generate")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.orange)
                        .padding(.top, 4)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(cardColor)
                        .shadow(color: Color.black.opacity(isDarkMode ? 0.3 : 0.08), radius: 12, x: 0, y: 4)
                )
            }

            // Tone Selection Section
            toneSelectionSection

            // Slide Types Section
            slideTypesSection

            // Generate Button (only shown when no outline exists)
            if viewModel.presentationOutline == nil {
                Button {
                    HapticManager.shared.mediumTap()
                    Task {
                        await viewModel.generateOutline()
                    }
                } label: {
                    HStack(spacing: 12) {
                        if viewModel.isGeneratingOutline {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                            Text("Generating Outline...")
                        } else {
                            Image(systemName: "sparkles")
                                .font(.system(size: 18))
                            Text("Generate Presentation")
                        }
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.brandPrimary,
                                Color.brandLight
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: Color.brandPrimary.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .disabled(!viewModel.canGenerateOutline)
                .opacity(viewModel.canGenerateOutline ? 1 : 0.5)
                .padding(.top, 12)
            }
        }
    }

    // MARK: - Step 2: Outline Generated
    private var outlineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: "list.bullet.rectangle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color.brandPrimary)

                Text("Outline")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(textColor)
            }

            if let outline = viewModel.presentationOutline {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(outline.presentationTitle)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(textColor)
                            .lineLimit(3)

                        HStack(spacing: 8) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 12))
                                .foregroundColor(secondaryTextColor)

                            Text("\(outline.slides.count) slides")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(secondaryTextColor)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isDarkMode ? Color(red: 32/255, green: 36/255, blue: 48/255) : Color.white)
                    )

                    Button {
                        HapticManager.shared.lightTap()
                        viewModel.showOutlineEditor = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 18))
                            Text("Edit Outline")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.brandPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.brandPrimary.opacity(0.12))
                        .cornerRadius(14)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(cardColor)
                        .shadow(color: Color.black.opacity(isDarkMode ? 0.3 : 0.08), radius: 12, x: 0, y: 4)
                )
            }
        }
    }

    // MARK: - Template Selection
    private var templateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color.brandPrimary)

                Text("Template")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(textColor)
            }

            Button {
                HapticManager.shared.selection()
                showTemplateSelection = true
            } label: {
                HStack(spacing: 16) {
                    // Color swatches
                    HStack(spacing: 8) {
                        Circle()
                            .fill(viewModel.selectedTemplate.primaryColor)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1.5)
                            )

                        Circle()
                            .fill(viewModel.selectedTemplate.secondaryColor)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1.5)
                            )

                        Circle()
                            .fill(viewModel.selectedTemplate.accentColor)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1.5)
                            )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(viewModel.selectedTemplate.name)
                            .foregroundColor(textColor)
                            .font(.system(size: 16, weight: .semibold))

                        Text(viewModel.selectedTemplate.description)
                            .foregroundColor(secondaryTextColor)
                            .font(.system(size: 13))
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(secondaryTextColor.opacity(0.5))
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isDarkMode ? Color(red: 32/255, green: 36/255, blue: 48/255) : Color.white)
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(cardColor)
                    .shadow(color: Color.black.opacity(isDarkMode ? 0.3 : 0.08), radius: 12, x: 0, y: 4)
            )
        }
    }

    // MARK: - Tone Selection Section
    private var toneSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: "waveform")
                    .font(.system(size: 15))
                    .foregroundColor(Color.brandPrimary)

                Text("Tone")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(textColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Choose your presentation style")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(secondaryTextColor)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(PresentationTone.allCases) { tone in
                            Button {
                                HapticManager.shared.lightTap()
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.selectedTone = tone
                                }
                            } label: {
                                VStack(spacing: 4) {
                                    // Icon
                                    ZStack {
                                        Circle()
                                            .fill(viewModel.selectedTone == tone ?
                                                  LinearGradient(
                                                    colors: [
                                                        Color.brandPrimary,
                                                        Color.brandLight
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                  ) :
                                                  LinearGradient(
                                                    colors: [cardColor, cardColor],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                  ))
                                            .frame(width: 38, height: 38)

                                        Image(systemName: tone.icon)
                                            .font(.system(size: 16))
                                            .foregroundColor(viewModel.selectedTone == tone ?
                                                            .white :
                                                            secondaryTextColor)
                                    }

                                    // Tone name
                                    Text(tone.displayName)
                                        .font(.system(size: 10, weight: viewModel.selectedTone == tone ? .semibold : .medium))
                                        .foregroundColor(viewModel.selectedTone == tone ? textColor : secondaryTextColor)
                                        .lineLimit(1)
                                }
                                .frame(width: 68)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(isDarkMode ? Color(red: 32/255, green: 36/255, blue: 48/255) : Color.white)
                                        .shadow(color: viewModel.selectedTone == tone ?
                                                Color.brandPrimary.opacity(0.3) :
                                                Color.black.opacity(isDarkMode ? 0.2 : 0.05),
                                                radius: viewModel.selectedTone == tone ? 5 : 2,
                                                x: 0,
                                                y: viewModel.selectedTone == tone ? 2 : 1)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .strokeBorder(
                                                    viewModel.selectedTone == tone ?
                                                    Color.brandPrimary :
                                                    Color.clear,
                                                    lineWidth: 1.5
                                                )
                                        )
                                )
                            }
                            .disabled(viewModel.isGeneratingOutline)
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 2)
                }

                // Custom Tone TextField (shown when Custom is selected)
                if viewModel.selectedTone == .custom {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("", text: $viewModel.customToneText, prompt: Text("e.g., Sarcastic but professional").foregroundColor(secondaryTextColor.opacity(0.6)))
                            .font(.system(size: 13))
                            .foregroundColor(textColor)
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isDarkMode ? Color(red: 32/255, green: 36/255, blue: 48/255) : Color.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Color.brandPrimary.opacity(0.2), lineWidth: 1)
                            )
                            .disabled(viewModel.isGeneratingOutline)
                            .onChange(of: viewModel.customToneText) { newValue in
                                // Limit to 100 characters
                                if newValue.count > 100 {
                                    viewModel.customToneText = String(newValue.prefix(100))
                                }
                            }

                        HStack {
                            if viewModel.customToneText.isEmpty {
                                Text("Custom tone description required")
                                    .font(.system(size: 10))
                                    .foregroundColor(.red.opacity(0.8))
                            }

                            Spacer()

                            Text("\(viewModel.customToneText.count)/100")
                                .font(.system(size: 10))
                                .foregroundColor(secondaryTextColor)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(cardColor)
                    .shadow(color: Color.black.opacity(isDarkMode ? 0.3 : 0.08), radius: 12, x: 0, y: 4)
            )
        }
    }

    // MARK: - Slide Types Section
    private var slideTypesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.system(size: 15))
                    .foregroundColor(Color.brandPrimary)

                Text("Slide Types")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(textColor)
            }

            VStack(alignment: .leading, spacing: 12) {
                // Mode Picker (Dynamic vs Custom)
                Picker("", selection: $viewModel.slideTypeMode) {
                    Text("Dynamic (Auto)").tag(SlideTypeMode.dynamic)
                    Text("Custom Selection").tag(SlideTypeMode.custom)
                }
                .pickerStyle(.segmented)
                .disabled(viewModel.isGeneratingOutline)

                // Custom slide type checkboxes (only shown in Custom mode)
                if viewModel.slideTypeMode == .custom {
                    VStack(spacing: 10) {
                        ForEach(SlideType.allCases) { slideType in
                            Button {
                                HapticManager.shared.lightTap()
                                toggleSlideType(slideType)
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: viewModel.selectedSlideTypes.contains(slideType) ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 22))
                                        .foregroundColor(viewModel.selectedSlideTypes.contains(slideType) ? Color.brandPrimary : secondaryTextColor.opacity(0.4))

                                    Image(systemName: slideType.icon)
                                        .font(.system(size: 16))
                                        .foregroundColor(viewModel.selectedSlideTypes.contains(slideType) ? textColor : secondaryTextColor)
                                        .frame(width: 24)

                                    Text(slideType.displayName)
                                        .font(.system(size: 15, weight: viewModel.selectedSlideTypes.contains(slideType) ? .medium : .regular))
                                        .foregroundColor(viewModel.selectedSlideTypes.contains(slideType) ? textColor : secondaryTextColor)

                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(isDarkMode ? Color(red: 32/255, green: 36/255, blue: 48/255) : Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .strokeBorder(
                                                    viewModel.selectedSlideTypes.contains(slideType) ?
                                                    Color.brandPrimary.opacity(0.3) :
                                                    Color.clear,
                                                    lineWidth: 1.5
                                                )
                                        )
                                )
                            }
                            .disabled(viewModel.isGeneratingOutline)
                        }

                        if viewModel.selectedSlideTypes.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red.opacity(0.8))

                                Text("Select at least one slide type")
                                    .font(.system(size: 13))
                                    .foregroundColor(.red.opacity(0.8))
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.top, 8)
                } else {
                    // Show info text for Dynamic mode
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16))
                            .foregroundColor(Color.brandPrimary)

                        Text("Automatically selects the best slide types for your content")
                            .font(.system(size: 14))
                            .foregroundColor(secondaryTextColor)
                            .lineLimit(2)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.brandPrimary.opacity(0.1))
                    )
                    .padding(.top, 6)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(cardColor)
                    .shadow(color: Color.black.opacity(isDarkMode ? 0.3 : 0.08), radius: 12, x: 0, y: 4)
            )
        }
    }

    private func toggleSlideType(_ type: SlideType) {
        if viewModel.selectedSlideTypes.contains(type) {
            viewModel.selectedSlideTypes.remove(type)
        } else {
            viewModel.selectedSlideTypes.insert(type)
        }
    }

    private func checkAndShowLaunchPaywall() {
        // Don't show if already shown in this session
        guard !showLaunchPaywall else {
            print("[Paywall] Already shown in this session")
            isCheckingPaywall = false
            return
        }

        // Don't show if onboarding is still showing (onboarding handles its own paywall)
        guard !showOnboarding else {
            print("[Paywall] Onboarding is active, skipping launch paywall")
            isCheckingPaywall = false
            return
        }

        // Don't show if user just completed onboarding (onboarding already showed paywall if needed)
        guard !justCompletedOnboarding else {
            print("[Paywall] Just completed onboarding, skipping launch paywall")
            isCheckingPaywall = false
            return
        }

        let settings = PaywallSettingsService.shared.getSettings()

        // Check premium status and limits
        Task {
            let hasPremium = await RevenueCatService.shared.hasPremiumAccess()
            print("[Paywall] Checking at launch - Has premium: \(hasPremium)")

            // Premium users never see paywall
            if hasPremium {
                print("[Paywall] Not showing - User has premium access")
                await MainActor.run {
                    isCheckingPaywall = false
                }
                return
            }

            // Check if limit is already reached
            let limitReached = await LimitTrackingService.shared.hasReachedAnyLimit()
            print("[Paywall] Limit reached: \(limitReached)")

            await MainActor.run {
                // Show paywall if:
                // 1. showPaywallOnStart is true (always show for non-premium), OR
                // 2. showPaywallOnStart is false BUT limit is already reached
                if settings.showPaywallOnStart || limitReached {
                    print("[Paywall] Showing launch paywall (showPaywallOnStart: \(settings.showPaywallOnStart), limitReached: \(limitReached))...")
                    showLaunchPaywall = true
                } else {
                    print("[Paywall] Not showing - showPaywallOnStart is false and limit not reached")
                }
                isCheckingPaywall = false
            }
        }
    }

    // MARK: - Generate Button
    private var generateButtonSection: some View {
        VStack(spacing: 14) {
            Button {
                HapticManager.shared.mediumTap()
                Task {
                    await viewModel.generatePresentation()
                }
            } label: {
                HStack(spacing: 12) {
                    if viewModel.isGeneratingPresentation {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                        Text("Creating Presentation...")
                    } else {
                        Image(systemName: "doc.richtext.fill")
                            .font(.system(size: 18))
                        Text("Create Presentation")
                    }
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [
                            Color.brandPrimary,
                            Color.brandLight
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: Color.brandPrimary.opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .disabled(!viewModel.canGeneratePresentation)
            .opacity(viewModel.canGeneratePresentation ? 1 : 0.5)

            Button {
                HapticManager.shared.lightTap()
                viewModel.resetToNewPresentation()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14))
                    Text("Start Over")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.red.opacity(0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.red.opacity(0.12))
                .cornerRadius(14)
            }
        }
    }

    // MARK: - Limit Badge View
    private var limitBadgeView: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(badgeTextColor)

            Text("\(outlineUsageCount)/\(PaywallSettingsService.shared.getSettings().outlineLimit)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(badgeTextColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(badgeBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(badgeBorderColor, lineWidth: 1)
                )
        )
    }

    private var badgeTextColor: Color {
        let limit = PaywallSettingsService.shared.getSettings().outlineLimit
        let remainingPercent = Double(limit - outlineUsageCount) / Double(limit)

        if remainingPercent > 0.5 {
            return Color(red: 34/255, green: 197/255, blue: 94/255) // Green
        } else if remainingPercent > 0 {
            return Color(red: 251/255, green: 146/255, blue: 60/255) // Orange
        } else {
            return Color.red // Red when limit reached
        }
    }

    private var badgeBackgroundColor: Color {
        let limit = PaywallSettingsService.shared.getSettings().outlineLimit
        let remainingPercent = Double(limit - outlineUsageCount) / Double(limit)

        if remainingPercent > 0.5 {
            return Color(red: 34/255, green: 197/255, blue: 94/255).opacity(0.12)
        } else if remainingPercent > 0 {
            return Color(red: 251/255, green: 146/255, blue: 60/255).opacity(0.12)
        } else {
            return Color.red.opacity(0.12)
        }
    }

    private var badgeBorderColor: Color {
        let limit = PaywallSettingsService.shared.getSettings().outlineLimit
        let remainingPercent = Double(limit - outlineUsageCount) / Double(limit)

        if remainingPercent > 0.5 {
            return Color(red: 34/255, green: 197/255, blue: 94/255).opacity(0.3)
        } else if remainingPercent > 0 {
            return Color(red: 251/255, green: 146/255, blue: 60/255).opacity(0.3)
        } else {
            return Color.red.opacity(0.3)
        }
    }

    // MARK: - Helper Methods
    private func updateLimitStatus() {
        Task {
            let premium = await RevenueCatService.shared.hasPremiumAccess()
            let count = LimitTrackingService.shared.getOutlineCount()

            await MainActor.run {
                hasPremiumAccess = premium
                outlineUsageCount = count
            }
        }
    }
}

// MARK: - URL Identifiable Extension
extension URL: Identifiable {
    public var id: String { absoluteString }
}

// MARK: - Notification Name Extension
extension Notification.Name {
    static let outlineGenerated = Notification.Name("outlineGenerated")
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Share Helper
func shareFile(url: URL) {
    guard FileManager.default.fileExists(atPath: url.path) else {
        print("[Share] File not found at: \(url.path)")
        return
    }

    let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)

    // Find the key window and top-most view controller
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first(where: { $0.isKeyWindow }),
          var topController = window.rootViewController else {
        print("[Share] Could not find root view controller")
        return
    }

    // Navigate to the top-most presented controller
    while let presented = topController.presentedViewController {
        topController = presented
    }

    // For iPad, set the popover source
    if let popover = activityVC.popoverPresentationController {
        popover.sourceView = topController.view
        popover.sourceRect = CGRect(x: topController.view.bounds.midX, y: topController.view.bounds.midY, width: 0, height: 0)
        popover.permittedArrowDirections = []
    }

    topController.present(activityVC, animated: true)
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
