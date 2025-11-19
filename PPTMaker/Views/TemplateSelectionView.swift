//
//  TemplateSelectionView.swift
//  PPTMaker
//
//  View for selecting presentation template
//

import SwiftUI

struct TemplateSelectionView: View {
    @Binding var selectedTemplate: Template
    @Environment(\.dismiss) private var dismiss

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Template.templates) { template in
                        TemplateCard(
                            template: template,
                            isSelected: selectedTemplate.id == template.id
                        )
                        .onTapGesture {
                            selectedTemplate = template
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Template Card
struct TemplateCard: View {
    let template: Template
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Color Swatches
            HStack(spacing: 8) {
                Circle()
                    .fill(template.primaryColor)
                    .frame(width: 32, height: 32)

                Circle()
                    .fill(template.secondaryColor)
                    .frame(width: 32, height: 32)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }

            // Template Info
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(template.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}
