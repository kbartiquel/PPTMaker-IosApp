//
//  Template.swift
//  PPT Maker
//
//  Presentation design templates
//

import SwiftUI

// Template layout styles
enum TemplateStyle: String {
    case gradient = "gradient"
    case geometric = "geometric"
    case minimal = "minimal"
    case classic = "classic"
    case modern = "modern"
}

struct Template: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let primaryColor: Color
    let secondaryColor: Color
    let accentColor: Color
    let style: TemplateStyle

    // Available templates matching backend
    static let templates: [Template] = [
        Template(
            id: "corporate",
            name: "Corporate Professional",
            description: "Clean and professional design for business presentations",
            primaryColor: Color(red: 30/255, green: 58/255, blue: 138/255),
            secondaryColor: Color(red: 59/255, green: 130/255, blue: 246/255),
            accentColor: Color(red: 243/255, green: 244/255, blue: 246/255),
            style: .classic
        ),
        Template(
            id: "creative",
            name: "Creative Bold",
            description: "Vibrant and eye-catching design for creative presentations",
            primaryColor: Color(red: 139/255, green: 92/255, blue: 246/255),
            secondaryColor: Color(red: 236/255, green: 72/255, blue: 153/255),
            accentColor: Color(red: 251/255, green: 191/255, blue: 36/255),
            style: .geometric
        ),
        Template(
            id: "academic",
            name: "Academic Classic",
            description: "Traditional and scholarly design for academic presentations",
            primaryColor: Color(red: 30/255, green: 64/255, blue: 175/255),
            secondaryColor: Color(red: 251/255, green: 191/255, blue: 36/255),
            accentColor: Color(red: 254/255, green: 243/255, blue: 199/255),
            style: .classic
        ),
        Template(
            id: "minimal",
            name: "Minimal Modern",
            description: "Sleek and contemporary design with minimalist aesthetics",
            primaryColor: Color(red: 0/255, green: 0/255, blue: 0/255),
            secondaryColor: Color(red: 16/255, green: 185/255, blue: 129/255),
            accentColor: Color(red: 209/255, green: 213/255, blue: 219/255),
            style: .minimal
        ),
        Template(
            id: "warm",
            name: "Warm & Friendly",
            description: "Inviting and approachable design with warm colors",
            primaryColor: Color(red: 249/255, green: 115/255, blue: 22/255),
            secondaryColor: Color(red: 5/255, green: 150/255, blue: 105/255),
            accentColor: Color(red: 254/255, green: 243/255, blue: 199/255),
            style: .modern
        ),
        Template(
            id: "tech",
            name: "Tech Startup",
            description: "Modern gradient design for technology and innovation",
            primaryColor: Color(red: 79/255, green: 70/255, blue: 229/255),
            secondaryColor: Color(red: 124/255, green: 58/255, blue: 237/255),
            accentColor: Color(red: 147/255, green: 197/255, blue: 253/255),
            style: .gradient
        ),
        Template(
            id: "nature",
            name: "Nature Eco",
            description: "Earth-friendly green design for environmental topics",
            primaryColor: Color(red: 22/255, green: 101/255, blue: 52/255),
            secondaryColor: Color(red: 132/255, green: 204/255, blue: 22/255),
            accentColor: Color(red: 254/255, green: 240/255, blue: 138/255),
            style: .modern
        ),
        Template(
            id: "luxury",
            name: "Luxury Premium",
            description: "Elegant gold and dark design for high-end presentations",
            primaryColor: Color(red: 31/255, green: 41/255, blue: 55/255),
            secondaryColor: Color(red: 217/255, green: 119/255, blue: 6/255),
            accentColor: Color(red: 253/255, green: 224/255, blue: 71/255),
            style: .classic
        ),
        Template(
            id: "vibrant",
            name: "Vibrant Energy",
            description: "Bright and energetic multi-color scheme",
            primaryColor: Color(red: 219/255, green: 39/255, blue: 119/255),
            secondaryColor: Color(red: 234/255, green: 88/255, blue: 12/255),
            accentColor: Color(red: 168/255, green: 85/255, blue: 247/255),
            style: .geometric
        ),
        Template(
            id: "monochrome",
            name: "Monochrome Elegant",
            description: "Sophisticated black and white design",
            primaryColor: Color(red: 17/255, green: 24/255, blue: 39/255),
            secondaryColor: Color(red: 107/255, green: 114/255, blue: 128/255),
            accentColor: Color(red: 209/255, green: 213/255, blue: 219/255),
            style: .minimal
        ),
        Template(
            id: "sunset",
            name: "Sunset Glow",
            description: "Warm sunset colors with orange, pink, and coral",
            primaryColor: Color(red: 239/255, green: 68/255, blue: 68/255),
            secondaryColor: Color(red: 251/255, green: 146/255, blue: 60/255),
            accentColor: Color(red: 252/255, green: 211/255, blue: 77/255),
            style: .gradient
        ),
        Template(
            id: "ocean",
            name: "Ocean Blue",
            description: "Cool and calming ocean blues and teals",
            primaryColor: Color(red: 8/255, green: 145/255, blue: 178/255),
            secondaryColor: Color(red: 14/255, green: 165/255, blue: 233/255),
            accentColor: Color(red: 103/255, green: 232/255, blue: 249/255),
            style: .gradient
        ),
        Template(
            id: "dark",
            name: "Professional Dark",
            description: "Modern dark mode business theme",
            primaryColor: Color(red: 30/255, green: 41/255, blue: 59/255),
            secondaryColor: Color(red: 71/255, green: 85/255, blue: 105/255),
            accentColor: Color(red: 148/255, green: 163/255, blue: 184/255),
            style: .modern
        ),
        Template(
            id: "pastel",
            name: "Pastel Soft",
            description: "Gentle and calming pastel color scheme",
            primaryColor: Color(red: 167/255, green: 139/255, blue: 250/255),
            secondaryColor: Color(red: 251/255, green: 207/255, blue: 232/255),
            accentColor: Color(red: 196/255, green: 181/255, blue: 253/255),
            style: .modern
        ),
        Template(
            id: "retro",
            name: "Retro Vintage",
            description: "Classic 80s/90s inspired color palette",
            primaryColor: Color(red: 236/255, green: 72/255, blue: 153/255),
            secondaryColor: Color(red: 168/255, green: 85/255, blue: 247/255),
            accentColor: Color(red: 45/255, green: 212/255, blue: 191/255),
            style: .geometric
        )
    ]

    static func template(withId id: String) -> Template? {
        templates.first { $0.id == id }
    }
}
