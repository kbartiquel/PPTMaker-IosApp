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

    var body: some View {
        NavigationView {
            List {
                if let outline = viewModel.presentationOutline {
                    // Presentation Title Section
                    Section(header: Text("Presentation Title")) {
                        Text(outline.presentationTitle)
                            .font(.headline)
                    }

                    // Slides Section
                    Section(header: Text("Slides (\(outline.slides.count))")) {
                        ForEach(Array(outline.slides.enumerated()), id: \.element.id) { index, slide in
                            NavigationLink {
                                SlideEditorView(
                                    slide: slide,
                                    onSave: { updatedSlide in
                                        viewModel.updateSlide(at: index, with: updatedSlide)
                                    }
                                )
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Slide \(slide.slideNumber)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        if slide.isTitleSlide {
                                            Text("TITLE")
                                                .font(.caption2)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.blue.opacity(0.2))
                                                .cornerRadius(4)
                                        }
                                    }

                                    Text(slide.title)
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    if let subtitle = slide.subtitle, !subtitle.isEmpty {
                                        Text(subtitle)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    if let bullets = slide.bulletPoints, !bullets.isEmpty {
                                        Text("\(bullets.count) bullet points")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteSlides)
                    }
                }
            }
            .navigationTitle("Edit Outline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
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

    init(slide: SlideData, onSave: @escaping (SlideData) -> Void) {
        _slide = State(initialValue: slide)
        self.onSave = onSave
    }

    var body: some View {
        Form {
            Section(header: Text("Slide Title")) {
                TextField("Title", text: $slide.title)
            }

            if slide.isTitleSlide {
                Section(header: Text("Subtitle")) {
                    TextField("Subtitle", text: Binding(
                        get: { slide.subtitle ?? "" },
                        set: { slide.subtitle = $0.isEmpty ? nil : $0 }
                    ))
                }
            } else {
                Section(header: Text("Bullet Points")) {
                    ForEach(Array((slide.bulletPoints ?? []).enumerated()), id: \.offset) { index, bullet in
                        HStack(alignment: .top) {
                            Text("•")
                                .foregroundColor(.secondary)
                            TextField("Bullet point", text: Binding(
                                get: { slide.bulletPoints?[index] ?? "" },
                                set: { newValue in
                                    if slide.bulletPoints != nil {
                                        slide.bulletPoints![index] = newValue
                                    }
                                }
                            ))
                        }
                    }
                    .onDelete { offsets in
                        slide.bulletPoints?.remove(atOffsets: offsets)
                    }

                    Button {
                        if slide.bulletPoints != nil {
                            slide.bulletPoints?.append("")
                        } else {
                            slide.bulletPoints = [""]
                        }
                    } label: {
                        Label("Add Bullet Point", systemImage: "plus.circle.fill")
                    }
                }
            }
        }
        .navigationTitle("Edit Slide \(slide.slideNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    onSave(slide)
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
    }
}
