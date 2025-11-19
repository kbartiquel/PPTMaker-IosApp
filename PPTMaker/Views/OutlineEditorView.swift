//
//  OutlineEditorView.swift
//  PPTMaker
//
//  View for editing the AI-generated presentation outline
//

import SwiftUI

struct OutlineEditorView: View {
    @ObservedObject var viewModel: PresentationViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = true

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
                backgroundColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        if let outline = viewModel.presentationOutline {
                            // Presentation Title Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Presentation Title")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(secondaryTextColor)

                                Text(outline.presentationTitle)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(textColor)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(cardColor)
                                    .cornerRadius(12)
                            }

                            // Slides Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Slides (\(outline.slides.count))")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(secondaryTextColor)

                                ForEach(Array(outline.slides.enumerated()), id: \.element.id) { index, slide in
                                    NavigationLink {
                                        SlideEditorView(
                                            slide: slide,
                                            onSave: { updatedSlide in
                                                viewModel.updateSlide(at: index, with: updatedSlide)
                                            }
                                        )
                                    } label: {
                                        HStack(spacing: 12) {
                                            VStack(alignment: .leading, spacing: 6) {
                                                HStack(spacing: 8) {
                                                    Text("Slide \(slide.slideNumber)")
                                                        .font(.system(size: 12, weight: .medium))
                                                        .foregroundColor(secondaryTextColor)

                                                    if slide.isTitleSlide {
                                                        Text("TITLE")
                                                            .font(.system(size: 10, weight: .bold))
                                                            .foregroundColor(Color(red: 59/255, green: 130/255, blue: 246/255))
                                                            .padding(.horizontal, 6)
                                                            .padding(.vertical, 2)
                                                            .background(Color(red: 59/255, green: 130/255, blue: 246/255).opacity(0.2))
                                                            .cornerRadius(4)
                                                    }
                                                }

                                                Text(slide.title)
                                                    .font(.system(size: 15, weight: .medium))
                                                    .foregroundColor(textColor)
                                                    .lineLimit(1)

                                                if let subtitle = slide.subtitle, !subtitle.isEmpty {
                                                    Text(subtitle)
                                                        .font(.system(size: 13))
                                                        .foregroundColor(secondaryTextColor)
                                                        .lineLimit(1)
                                                }

                                                if let bullets = slide.bulletPoints, !bullets.isEmpty {
                                                    Text("\(bullets.count) bullet points")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(secondaryTextColor)
                                                }
                                            }

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14))
                                                .foregroundColor(secondaryTextColor.opacity(0.6))
                                        }
                                        .padding()
                                        .background(cardColor)
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Edit Outline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(isDarkMode ? .dark : .light, for: .navigationBar)
            .toolbarBackground(backgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(textColor)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 59/255, green: 130/255, blue: 246/255))
                    .fontWeight(.semibold)
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }

    private func deleteSlides(at offsets: IndexSet) {
        for index in offsets {
            viewModel.removeSlide(at: index)
        }
    }
}

// MARK: - Slide Editor View
struct SlideEditorView: View {
    @State private var slide: SlideData
    let onSave: (SlideData) -> Void
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = true

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

    init(slide: SlideData, onSave: @escaping (SlideData) -> Void) {
        _slide = State(initialValue: slide)
        self.onSave = onSave
    }

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Slide Title
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Slide Title")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(secondaryTextColor)

                        TextField("", text: $slide.title, prompt: Text("Enter slide title").foregroundColor(secondaryTextColor.opacity(0.6)))
                            .font(.system(size: 16))
                            .foregroundColor(textColor)
                            .padding()
                            .background(cardColor)
                            .cornerRadius(12)
                    }

                    if slide.isTitleSlide {
                        // Subtitle
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Subtitle")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(secondaryTextColor)

                            TextField("", text: Binding(
                                get: { slide.subtitle ?? "" },
                                set: { slide.subtitle = $0.isEmpty ? nil : $0 }
                            ), prompt: Text("Enter subtitle").foregroundColor(secondaryTextColor.opacity(0.6)))
                                .font(.system(size: 16))
                                .foregroundColor(textColor)
                                .padding()
                                .background(cardColor)
                                .cornerRadius(12)
                        }
                    } else {
                        // Bullet Points
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Bullet Points")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(secondaryTextColor)

                            ForEach(Array((slide.bulletPoints ?? []).enumerated()), id: \.offset) { index, bullet in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .font(.system(size: 16))
                                        .foregroundColor(secondaryTextColor)
                                        .padding(.top, 12)

                                    TextField("", text: Binding(
                                        get: { slide.bulletPoints?[index] ?? "" },
                                        set: { newValue in
                                            if slide.bulletPoints != nil {
                                                slide.bulletPoints![index] = newValue
                                            }
                                        }
                                    ), prompt: Text("Bullet point").foregroundColor(secondaryTextColor.opacity(0.6)))
                                        .font(.system(size: 16))
                                        .foregroundColor(textColor)
                                        .padding()
                                        .background(cardColor)
                                        .cornerRadius(12)
                                }
                            }

                            Button {
                                if slide.bulletPoints != nil {
                                    slide.bulletPoints?.append("")
                                } else {
                                    slide.bulletPoints = [""]
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Bullet Point")
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
                }
                .padding(20)
            }
        }
        .navigationTitle("Edit Slide \(slide.slideNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(isDarkMode ? .dark : .light, for: .navigationBar)
        .toolbarBackground(backgroundColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    onSave(slide)
                    dismiss()
                }
                .foregroundColor(Color(red: 59/255, green: 130/255, blue: 246/255))
                .fontWeight(.semibold)
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}
