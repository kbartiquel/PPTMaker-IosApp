//
//  ColorScheme.swift
//  PPTMaker
//
//  App-wide color scheme - Green theme matching app icon
//

import SwiftUI

extension Color {
    // MARK: - Primary Colors (Green Theme)

    /// Main brand color - matches icon background
    static let brandPrimary = Color(red: 74/255, green: 155/255, blue: 127/255) // #4A9B7F

    /// Darker green for buttons and emphasis
    static let brandAccent = Color(red: 61/255, green: 139/255, blue: 107/255) // #3D8B6B

    /// Light green for highlights and hover states
    static let brandLight = Color(red: 109/255, green: 184/255, blue: 157/255) // #6DB89D

    /// Very light green for backgrounds
    static let brandSuperLight = Color(red: 74/255, green: 155/255, blue: 127/255).opacity(0.1)

    // MARK: - Gradient Colors

    /// Primary gradient (green theme)
    static let gradientStart = Color(red: 74/255, green: 155/255, blue: 127/255)
    static let gradientEnd = Color(red: 109/255, green: 184/255, blue: 157/255)

    /// Alternative gradient (teal accent)
    static let gradientTealStart = Color(red: 61/255, green: 139/255, blue: 107/255)
    static let gradientTealEnd = Color(red: 32/255, green: 201/255, blue: 151/255)

    // MARK: - Feature Colors

    /// Success/completion color
    static let brandSuccess = Color(red: 52/255, green: 199/255, blue: 89/255) // iOS native green

    /// Warning color
    static let brandWarning = Color(red: 255/255, green: 149/255, blue: 0/255)

    /// Error color
    static let brandError = Color.red

    // MARK: - Badge Colors

    /// Badge color - green for available credits
    static let badgeGreen = Color(red: 34/255, green: 197/255, blue: 94/255)

    /// Badge color - orange for low credits
    static let badgeOrange = Color(red: 251/255, green: 146/255, blue: 60/255)

    /// Badge color - red for no credits
    static let badgeRed = Color.red
}
