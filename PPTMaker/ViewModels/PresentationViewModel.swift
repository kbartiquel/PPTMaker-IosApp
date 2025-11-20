//
//  PresentationViewModel.swift
//  PPTMaker
//
//  Main view model for managing presentation creation workflow
//

import Foundation
import SwiftUI
import Combine

@MainActor
class PresentationViewModel: ObservableObject {
    // MARK: - Published Properties

    // Step 1: Topic Input
    @Published var topic: String = ""
    @Published var numSlides: Int = 8

    // Slide Type Selection
    @Published var slideTypeMode: SlideTypeMode = .dynamic
    @Published var selectedSlideTypes: Set<SlideType> = Set(SlideType.allCases)

    // Step 2: Generated Outline (editable)
    @Published var presentationOutline: PresentationOutline?
    @Published var isGeneratingOutline: Bool = false

    // Step 3: Template Selection
    @Published var selectedTemplate: Template = Template.templates[0]

    // Step 4: Final Presentation
    @Published var isGeneratingPresentation: Bool = false
    @Published var generatedFileURL: URL?

    // UI State
    @Published var errorMessage: String?
    @Published var showSuccess: Bool = false
    @Published var showOutlineEditor: Bool = false

    // MARK: - Services
    private let apiService = APIService()
    private let fileService = FileService()

    // MARK: - Computed Properties
    var canGenerateOutline: Bool {
        let hasValidSlideTypes = slideTypeMode == .dynamic || !selectedSlideTypes.isEmpty
        return !topic.isEmpty && !isGeneratingOutline && hasValidSlideTypes
    }

    var canGeneratePresentation: Bool {
        presentationOutline != nil && !isGeneratingPresentation
    }

    var currentStep: Int {
        if presentationOutline == nil {
            return 1 // Topic input
        } else if generatedFileURL == nil {
            return 2 // Outline editing / template selection
        } else {
            return 3 // Complete
        }
    }

    // MARK: - Step 1: Generate Outline
    func generateOutline() async {
        guard canGenerateOutline else { return }

        isGeneratingOutline = true
        errorMessage = nil

        do {
            // Prepare allowed slide types
            let allowedTypes: [String]? = slideTypeMode == .dynamic ? nil : Array(selectedSlideTypes.map { $0.rawValue })

            let outline = try await apiService.generateOutline(
                topic: topic,
                numSlides: numSlides,
                allowedSlideTypes: allowedTypes
            )

            presentationOutline = outline
            showOutlineEditor = true

        } catch {
            errorMessage = error.localizedDescription
        }

        isGeneratingOutline = false
    }

    // MARK: - Step 2: Edit Outline (handled in view)
    func updateSlide(at index: Int, with newSlide: SlideData) {
        guard var outline = presentationOutline else { return }
        guard index < outline.slides.count else { return }

        outline.slides[index] = newSlide
        presentationOutline = outline
    }

    func removeSlide(at index: Int) {
        guard var outline = presentationOutline else { return }
        guard index < outline.slides.count else { return }

        outline.slides.remove(at: index)
        // Update slide numbers
        for i in 0..<outline.slides.count {
            outline.slides[i] = SlideData(
                slideNumber: i + 1,
                type: outline.slides[i].type,
                title: outline.slides[i].title,
                subtitle: outline.slides[i].subtitle,
                bulletPoints: outline.slides[i].bulletPoints
            )
        }
        presentationOutline = outline
    }

    // MARK: - Step 3: Generate Final Presentation
    func generatePresentation() async {
        guard let outline = presentationOutline else { return }
        guard canGeneratePresentation else { return }

        isGeneratingPresentation = true
        errorMessage = nil

        do {
            let data = try await apiService.generatePresentation(
                presentationTitle: outline.presentationTitle,
                slides: outline.slides,
                template: selectedTemplate.id
            )

            let filename = fileService.generateFilename(from: outline.presentationTitle)
            let fileURL = try fileService.savePresentation(data, filename: filename)

            // Save outline JSON for later editing (with template info)
            var outlineWithTemplate = outline
            outlineWithTemplate.template = selectedTemplate.id
            try fileService.saveOutline(outlineWithTemplate, for: fileURL)

            generatedFileURL = fileURL
            showSuccess = true

        } catch {
            errorMessage = error.localizedDescription
        }

        isGeneratingPresentation = false
    }

    // MARK: - Load Outline from History
    func loadOutlineFromHistory(pptxURL: URL) {
        if let outline = fileService.loadOutline(for: pptxURL) {
            presentationOutline = outline
            topic = "" // Clear topic since we're editing existing
            showOutlineEditor = true
        } else {
            errorMessage = "Could not load outline data for this presentation"
        }
    }

    // MARK: - Reset State
    func resetToNewPresentation() {
        topic = ""
        numSlides = 8
        presentationOutline = nil
        selectedTemplate = Template.templates[0]
        generatedFileURL = nil
        showSuccess = false
        showOutlineEditor = false
        errorMessage = nil
    }

    func resetAfterSuccess() {
        topic = ""
        numSlides = 8
        presentationOutline = nil
        generatedFileURL = nil
        showSuccess = false
        showOutlineEditor = false
    }
}

// MARK: - Slide Type Selection Enums
enum SlideTypeMode {
    case dynamic
    case custom
}

enum SlideType: String, CaseIterable, Identifiable {
    case content = "content"
    case section = "section"
    case quote = "quote"
    case twoColumn = "two-column"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .content: return "Content (bullet points)"
        case .section: return "Section headers"
        case .quote: return "Quotes"
        case .twoColumn: return "Two-column comparisons"
        }
    }

    var icon: String {
        switch self {
        case .content: return "list.bullet"
        case .section: return "textformat.size"
        case .quote: return "quote.bubble"
        case .twoColumn: return "rectangle.split.2x1"
        }
    }
}
