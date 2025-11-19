//
//  PresentationHistoryView.swift
//  PPTMaker
//
//  View for browsing and managing saved presentations
//

import SwiftUI

struct PresentationHistoryView: View {
    @State private var savedPresentations: [URL] = []
    @State private var selectedPresentation: URL?
    @State private var showDeleteAlert = false
    @State private var presentationToDelete: URL?

    private let fileService = FileService()

    var body: some View {
        NavigationView {
            Group {
                if savedPresentations.isEmpty {
                    emptyStateView
                } else {
                    presentationListView
                }
            }
            .navigationTitle("My Presentations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        refreshList()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                refreshList()
            }
            .sheet(item: $selectedPresentation) { url in
                QuickLookPreview(url: url)
            }
            .alert("Delete Presentation", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let url = presentationToDelete {
                        deletePresentation(url)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this presentation?")
            }
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No Presentations Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Create your first presentation to see it here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Presentation List
    private var presentationListView: some View {
        List {
            ForEach(savedPresentations, id: \.self) { url in
                PresentationRow(url: url)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        HapticManager.shared.impact(style: .light)
                        selectedPresentation = url
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            presentationToDelete = url
                            showDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            sharePresentation(url)
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .tint(.blue)
                    }
            }
        }
    }

    // MARK: - Actions
    private func refreshList() {
        savedPresentations = fileService.listSavedPresentations()
    }

    private func deletePresentation(_ url: URL) {
        do {
            try fileService.deletePresentation(at: url)
            HapticManager.shared.notification(type: .success)
            refreshList()
        } catch {
            HapticManager.shared.notification(type: .error)
            print("Error deleting presentation: \(error)")
        }
    }

    private func sharePresentation(_ url: URL) {
        HapticManager.shared.impact(style: .medium)
        // Share via system share sheet
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Presentation Row
struct PresentationRow: View {
    let url: URL
    @State private var fileDate: Date?
    @State private var fileSize: String?

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: "doc.richtext.fill")
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(url.deletingPathExtension().lastPathComponent)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if let date = fileDate {
                        Text(date, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let size = fileSize {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(size)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .onAppear {
            loadFileInfo()
        }
    }

    private func loadFileInfo() {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            fileDate = attributes[.creationDate] as? Date

            if let size = attributes[.size] as? Int64 {
                fileSize = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            }
        } catch {
            print("Error loading file info: \(error)")
        }
    }
}

// MARK: - Quick Look Preview
import QuickLook

struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return url as QLPreviewItem
        }
    }
}
