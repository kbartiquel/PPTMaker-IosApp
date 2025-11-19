//
//  TemplateSelectionView.swift
//  PPTMaker
//
//  View for selecting presentation template with visual previews
//

import SwiftUI

struct TemplateSelectionView: View {
    @Binding var selectedTemplate: Template
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 18/255, green: 18/255, blue: 24/255)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(Template.templates) { template in
                            TemplatePreviewCard(
                                template: template,
                                isSelected: selectedTemplate.id == template.id
                            )
                            .onTapGesture {
                                HapticManager.shared.selection()
                                selectedTemplate = template
                                dismiss()
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Choose Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color(red: 18/255, green: 18/255, blue: 24/255), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 59/255, green: 130/255, blue: 246/255))
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Template Preview Card with Visual Representation
struct TemplatePreviewCard: View {
    let template: Template
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Visual Preview
            TemplatePreview(template: template)
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            // Template Info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)

                        Text(template.description)
                            .font(.system(size: 13))
                            .foregroundColor(Color.white.opacity(0.6))
                            .lineLimit(2)
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(red: 59/255, green: 130/255, blue: 246/255))
                            .font(.system(size: 24))
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(red: 28/255, green: 32/255, blue: 42/255))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color(red: 59/255, green: 130/255, blue: 246/255) : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Template Preview Visual
struct TemplatePreview: View {
    let template: Template

    var body: some View {
        ZStack {
            // Background
            Rectangle()
                .fill(Color.white)

            // Style-specific layouts
            switch template.style {
            case .gradient:
                GradientStylePreview(template: template)
            case .geometric:
                GeometricStylePreview(template: template)
            case .minimal:
                MinimalStylePreview(template: template)
            case .classic:
                ClassicStylePreview(template: template)
            case .modern:
                ModernStylePreview(template: template)
            }
        }
    }
}

// MARK: - Gradient Style Preview
struct GradientStylePreview: View {
    let template: Template

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [template.primaryColor, template.secondaryColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Decorative circles
            Circle()
                .fill(template.accentColor.opacity(0.3))
                .frame(width: 60, height: 60)
                .offset(x: 80, y: -50)

            Circle()
                .fill(template.secondaryColor.opacity(0.4))
                .frame(width: 40, height: 40)
                .offset(x: -70, y: 50)

            // Title bar mockup
            VStack {
                Spacer()
                Rectangle()
                    .fill(template.primaryColor)
                    .frame(height: 30)
            }

            // Title text mockup
            VStack(spacing: 4) {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 120, height: 12)
                    .cornerRadius(2)

                Rectangle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 80, height: 8)
                    .cornerRadius(2)
            }
        }
    }
}

// MARK: - Geometric Style Preview
struct GeometricStylePreview: View {
    let template: Template

    var body: some View {
        ZStack {
            Color.white

            // Diagonal accent shape
            Rectangle()
                .fill(template.primaryColor)
                .frame(width: 200, height: 80)
                .rotationEffect(.degrees(15))
                .offset(x: 50, y: -40)

            // Top bar
            VStack {
                Rectangle()
                    .fill(template.secondaryColor)
                    .frame(height: 25)
                Spacer()
            }

            // Geometric shapes
            Circle()
                .fill(template.accentColor)
                .frame(width: 35, height: 35)
                .offset(x: -65, y: 30)

            RoundedRectangle(cornerRadius: 4)
                .fill(template.primaryColor.opacity(0.3))
                .frame(width: 50, height: 50)
                .offset(x: 60, y: 45)

            // Text mockup
            VStack(alignment: .leading, spacing: 4) {
                Rectangle()
                    .fill(template.primaryColor)
                    .frame(width: 100, height: 10)
                    .cornerRadius(2)

                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 70, height: 6)
                    .cornerRadius(2)

                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 85, height: 6)
                    .cornerRadius(2)
            }
            .offset(x: -25, y: 0)
        }
    }
}

// MARK: - Minimal Style Preview
struct MinimalStylePreview: View {
    let template: Template

    var body: some View {
        ZStack {
            Color.white

            // Simple accent line
            VStack {
                Rectangle()
                    .fill(template.primaryColor)
                    .frame(height: 3)
                Spacer()
            }

            // Minimal title
            VStack(spacing: 8) {
                Rectangle()
                    .fill(template.primaryColor)
                    .frame(width: 140, height: 14)
                    .cornerRadius(2)

                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 8)
                    .cornerRadius(2)
            }
            .offset(y: -30)

            // Clean bullet points
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(template.secondaryColor)
                        .frame(width: 4, height: 4)
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 80, height: 6)
                        .cornerRadius(2)
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(template.secondaryColor)
                        .frame(width: 4, height: 4)
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 70, height: 6)
                        .cornerRadius(2)
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(template.secondaryColor)
                        .frame(width: 4, height: 4)
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 75, height: 6)
                        .cornerRadius(2)
                }
            }
            .offset(y: 25)
        }
    }
}

// MARK: - Classic Style Preview
struct ClassicStylePreview: View {
    let template: Template

    var body: some View {
        ZStack {
            Color.white

            // Classic top bar
            VStack {
                Rectangle()
                    .fill(template.primaryColor)
                    .frame(height: 30)
                Spacer()
            }

            // Decorative bottom accent
            VStack {
                Spacer()
                Rectangle()
                    .fill(template.secondaryColor)
                    .frame(height: 8)
            }

            // Title in bar
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 100, height: 12)
                    .cornerRadius(2)
                    .padding(.top, 9)

                Spacer()
            }

            // Traditional bullet layout
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(template.secondaryColor)
                        .frame(width: 5, height: 5)
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 90, height: 7)
                        .cornerRadius(2)
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(template.secondaryColor)
                        .frame(width: 5, height: 5)
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 75, height: 7)
                        .cornerRadius(2)
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(template.secondaryColor)
                        .frame(width: 5, height: 5)
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 85, height: 7)
                        .cornerRadius(2)
                }
            }
            .offset(y: 10)

            // Side accent bar
            HStack {
                Rectangle()
                    .fill(template.accentColor)
                    .frame(width: 4)
                Spacer()
            }
        }
    }
}

// MARK: - Modern Style Preview
struct ModernStylePreview: View {
    let template: Template

    var body: some View {
        ZStack {
            Color.white

            // Modern colored header
            VStack {
                Rectangle()
                    .fill(template.primaryColor)
                    .frame(height: 28)
                Spacer()
            }

            // Accent stripe
            HStack {
                Rectangle()
                    .fill(template.secondaryColor)
                    .frame(width: 5)
                    .padding(.top, 28)
                Spacer()
            }

            // Title in header
            VStack {
                HStack {
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 90, height: 11)
                        .cornerRadius(2)
                        .padding(.leading, 10)
                        .padding(.top, 8)
                    Spacer()
                }
                Spacer()
            }

            // Modern content blocks
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(template.secondaryColor)
                        .frame(width: 5, height: 5)
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 85, height: 7)
                        .cornerRadius(2)
                }

                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(template.secondaryColor)
                        .frame(width: 5, height: 5)
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 70, height: 7)
                        .cornerRadius(2)
                }

                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(template.secondaryColor)
                        .frame(width: 5, height: 5)
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 80, height: 7)
                        .cornerRadius(2)
                }
            }
            .offset(x: -15, y: 15)

            // Decorative element
            Circle()
                .fill(template.accentColor.opacity(0.2))
                .frame(width: 45, height: 45)
                .offset(x: 70, y: -50)
        }
    }
}
