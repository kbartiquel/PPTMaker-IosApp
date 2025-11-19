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
            Form {
                // Step 1: Topic Input
                topicInputSection

                // Step 2: Outline Generated - Edit and Template Selection
                if viewModel.presentationOutline != nil {
                    outlineSection
                    templateSelectionSection
                }

                // Generate Button Section
                generateButtonSection
            }
            .navigationTitle("PPT Maker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticManager.shared.lightTap()
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
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
            .sheet(isPresented: $showOnboarding) {
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

    // MARK: - Step 1: Topic Input
    private var topicInputSection: some View {
        Section(header: Text("Step 1: Enter Topic")) {
            TextField("Presentation topic", text: $viewModel.topic)
                .disabled(viewModel.isGeneratingOutline)

            Stepper("Number of slides: \(viewModel.numSlides)", value: $viewModel.numSlides, in: 5...15)
                .disabled(viewModel.isGeneratingOutline)

            if viewModel.presentationOutline == nil {
                Button {
                    HapticManager.shared.mediumTap()
                    Task {
                        await viewModel.generateOutline()
                    }
                } label: {
                    HStack {
                        if viewModel.isGeneratingOutline {
                            ProgressView()
                                .progressViewStyle(.circular)
                            Text("Generating outline...")
                        } else {
                            Text("Generate Outline")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canGenerateOutline)
            }
        }
    }

    // MARK: - Step 2: Outline Generated
    private var outlineSection: some View {
        Section(header: Text("Step 2: Review Outline")) {
            if let outline = viewModel.presentationOutline {
                VStack(alignment: .leading, spacing: 8) {
                    Text(outline.presentationTitle)
                        .font(.headline)

                    Text("\(outline.slides.count) slides")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button {
                    HapticManager.shared.lightTap()
                    viewModel.showOutlineEditor = true
                } label: {
                    Label("Edit Outline", systemImage: "pencil")
                }
            }
        }
    }

    // MARK: - Template Selection
    private var templateSelectionSection: some View {
        Section(header: Text("Step 3: Choose Template")) {
            Button {
                HapticManager.shared.selection()
                showTemplateSelection = true
            } label: {
                HStack {
                    // Color swatches
                    HStack(spacing: 4) {
                        Circle()
                            .fill(viewModel.selectedTemplate.primaryColor)
                            .frame(width: 24, height: 24)

                        Circle()
                            .fill(viewModel.selectedTemplate.secondaryColor)
                            .frame(width: 24, height: 24)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.selectedTemplate.name)
                            .foregroundColor(.primary)
                            .font(.subheadline)

                        Text(viewModel.selectedTemplate.description)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
    }

    // MARK: - Generate Button
    private var generateButtonSection: some View {
        Section {
            if viewModel.presentationOutline != nil {
                Button {
                    HapticManager.shared.mediumTap()
                    Task {
                        await viewModel.generatePresentation()
                    }
                } label: {
                    HStack {
                        if viewModel.isGeneratingPresentation {
                            ProgressView()
                                .progressViewStyle(.circular)
                            Text("Creating presentation...")
                        } else {
                            Image(systemName: "doc.richtext")
                            Text("Generate Presentation")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canGeneratePresentation)
            }

            if viewModel.presentationOutline != nil {
                Button("Start Over", role: .destructive) {
                    HapticManager.shared.lightTap()
                    viewModel.resetToNewPresentation()
                }
            }
        }
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
