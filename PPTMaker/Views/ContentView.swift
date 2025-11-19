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
    @State private var shareItem: URL?
    @State private var showHistory = false
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    @State private var previewURL: URL?

    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                Color(red: 18/255, green: 18/255, blue: 24/255)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // App Header with Title and Icon (only show initially)
                        if viewModel.presentationOutline == nil {
                            appHeaderSection
                        }

                        // Step 1: Topic Input
                        topicInputSection

                        // Step 2: Outline Generated - Edit and Template Selection
                        if viewModel.presentationOutline != nil {
                            outlineSection
                            templateSelectionSection
                            generateButtonSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle(viewModel.presentationOutline == nil ? "" : "Presentation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color(red: 18/255, green: 18/255, blue: 24/255), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticManager.shared.lightTap()
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showOutlineEditor) {
                OutlineEditorView(viewModel: viewModel)
            }
            .sheet(isPresented: $showTemplateSelection) {
                TemplateSelectionView(selectedTemplate: $viewModel.selectedTemplate)
            }
            .sheet(item: $shareItem) { url in
                ShareSheet(items: [url])
            }
            .sheet(isPresented: $showHistory) {
                PresentationHistoryView()
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView(isPresented: $showOnboarding)
            }
            .sheet(item: $previewURL) { url in
                QuickLookPreview(url: url)
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
                        previewURL = url
                    }
                }
                Button("Share") {
                    HapticManager.shared.lightTap()
                    if let url = viewModel.generatedFileURL {
                        shareItem = url
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
    }

    // MARK: - App Header
    private var appHeaderSection: some View {
        VStack(spacing: 12) {
            // App Icon
            ZStack {
                // Gradient background circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 59/255, green: 130/255, blue: 246/255),
                                Color(red: 99/255, green: 102/255, blue: 241/255)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: Color(red: 59/255, green: 130/255, blue: 246/255).opacity(0.3), radius: 10, x: 0, y: 5)

                // Icon
                Image(systemName: "doc.richtext.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }

            // App Title
            VStack(spacing: 4) {
                Text("PPT Maker")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)

                Text("AI-Powered Presentations")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.bottom, 8)
    }

    // MARK: - Step 1: Topic Input
    private var topicInputSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Topic Input
            VStack(alignment: .leading, spacing: 12) {
                Text("Presentation Topic")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)

                TextField("", text: $viewModel.topic, prompt: Text("e.g., 'The Future of Renewable Energy'").foregroundColor(Color.white.opacity(0.4)))
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color(red: 28/255, green: 32/255, blue: 42/255))
                    .cornerRadius(12)
                    .disabled(viewModel.isGeneratingOutline)
            }

            // Number of Slides
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Number of Slides")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)

                    Spacer()

                    Text("\(viewModel.numSlides)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }

                HStack(spacing: 12) {
                    Text("5")
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.6))

                    Slider(value: Binding(
                        get: { Double(viewModel.numSlides) },
                        set: { viewModel.numSlides = Int($0) }
                    ), in: 5...15, step: 1)
                    .accentColor(Color(red: 59/255, green: 130/255, blue: 246/255))
                    .disabled(viewModel.isGeneratingOutline)

                    Text("15")
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.6))
                }
            }

            // Generate Button (only shown when no outline exists)
            if viewModel.presentationOutline == nil {
                Button {
                    HapticManager.shared.mediumTap()
                    Task {
                        await viewModel.generateOutline()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isGeneratingOutline {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                            Text("Generating Outline...")
                        } else {
                            Text("Generate Presentation")
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(red: 59/255, green: 130/255, blue: 246/255))
                    .cornerRadius(12)
                }
                .disabled(!viewModel.canGenerateOutline)
                .opacity(viewModel.canGenerateOutline ? 1 : 0.5)
                .padding(.top, 8)
            }
        }
        .padding(.bottom, 24)
    }

    // MARK: - Step 2: Outline Generated
    private var outlineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Review Outline")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)

            if let outline = viewModel.presentationOutline {
                VStack(alignment: .leading, spacing: 12) {
                    Text(outline.presentationTitle)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text("\(outline.slides.count) slides")
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(red: 28/255, green: 32/255, blue: 42/255))
                .cornerRadius(12)

                Button {
                    HapticManager.shared.lightTap()
                    viewModel.showOutlineEditor = true
                } label: {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit Outline")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(red: 59/255, green: 130/255, blue: 246/255))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(red: 59/255, green: 130/255, blue: 246/255).opacity(0.15))
                    .cornerRadius(10)
                }
            }
        }
        .padding(.bottom, 24)
    }

    // MARK: - Template Selection
    private var templateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Template")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)

            Button {
                HapticManager.shared.selection()
                showTemplateSelection = true
            } label: {
                HStack(spacing: 12) {
                    // Color swatches
                    HStack(spacing: 6) {
                        Circle()
                            .fill(viewModel.selectedTemplate.primaryColor)
                            .frame(width: 24, height: 24)

                        Circle()
                            .fill(viewModel.selectedTemplate.secondaryColor)
                            .frame(width: 24, height: 24)

                        Circle()
                            .fill(viewModel.selectedTemplate.accentColor)
                            .frame(width: 24, height: 24)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.selectedTemplate.name)
                            .foregroundColor(.white)
                            .font(.system(size: 15, weight: .medium))

                        Text(viewModel.selectedTemplate.description)
                            .foregroundColor(Color.white.opacity(0.6))
                            .font(.system(size: 13))
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(Color.white.opacity(0.4))
                        .font(.system(size: 14))
                }
                .padding()
                .background(Color(red: 28/255, green: 32/255, blue: 42/255))
                .cornerRadius(12)
            }
        }
        .padding(.bottom, 24)
    }

    // MARK: - Generate Button
    private var generateButtonSection: some View {
        VStack(spacing: 16) {
            Button {
                HapticManager.shared.mediumTap()
                Task {
                    await viewModel.generatePresentation()
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isGeneratingPresentation {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                        Text("Creating Presentation...")
                    } else {
                        Image(systemName: "doc.richtext")
                        Text("Create Presentation")
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(red: 59/255, green: 130/255, blue: 246/255))
                .cornerRadius(12)
            }
            .disabled(!viewModel.canGeneratePresentation)
            .opacity(viewModel.canGeneratePresentation ? 1 : 0.5)

            Button {
                HapticManager.shared.lightTap()
                viewModel.resetToNewPresentation()
            } label: {
                Text("Start Over")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.red.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.15))
                    .cornerRadius(10)
            }
        }
        .padding(.bottom, 40)
    }
}

// MARK: - URL Identifiable Extension
extension URL: Identifiable {
    public var id: String { absoluteString }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
