//
//  SlideModels.swift
//  PPT Maker
//
//  Data models for slides and presentations
//

import Foundation

// MARK: - Outline Request (Step 1)
struct OutlineRequest: Codable {
    let topic: String
    let numSlides: Int

    enum CodingKeys: String, CodingKey {
        case topic
        case numSlides = "num_slides"
    }
}

// MARK: - Outline Response (from AI)
struct OutlineResponse: Codable {
    let status: String
    let outline: PresentationOutline
    let metadata: OutlineMetadata?
}

struct OutlineMetadata: Codable {
    let topic: String
    let requestedSlides: Int
    let generatedSlides: Int

    enum CodingKeys: String, CodingKey {
        case topic
        case requestedSlides = "requested_slides"
        case generatedSlides = "generated_slides"
    }
}

struct PresentationOutline: Codable {
    let presentationTitle: String
    var slides: [SlideData]
    var template: String?  // Template name used for this presentation

    enum CodingKeys: String, CodingKey {
        case presentationTitle = "presentation_title"
        case slides
        case template
    }
}

// MARK: - Slide Data (editable)
struct SlideData: Codable, Identifiable {
    var id: Int { slideNumber }
    let slideNumber: Int
    let type: String
    var title: String
    var subtitle: String?
    var bulletPoints: [String]?

    enum CodingKeys: String, CodingKey {
        case slideNumber = "slide_number"
        case type
        case title
        case subtitle
        case bulletPoints = "bullet_points"
    }

    var isTitleSlide: Bool {
        type == "title"
    }
}

// MARK: - Presentation Request (Step 2)
struct PresentationRequest: Codable {
    let presentationTitle: String
    let slides: [SlideData]
    let template: String

    enum CodingKeys: String, CodingKey {
        case presentationTitle = "presentation_title"
        case slides
        case template
    }
}
