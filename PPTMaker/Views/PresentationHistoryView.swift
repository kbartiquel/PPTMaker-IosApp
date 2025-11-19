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
            ZStack {
                Color(red: 18/255, green: 18/255, blue: 24/255)
                    .ignoresSafeArea()

                Group {
                    if savedPresentations.isEmpty {
                        emptyStateView
                    } else {
                        presentationListView
                    }
                }
            }
            .navigationTitle("My Presentations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color(red: 18/255, green: 18/255, blue: 24/255), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        refreshList()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white)
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
                .foregroundColor(Color.white.opacity(0.4))

            Text("No Presentations Yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)

            Text("Create your first presentation to see it here")
                .font(.system(size: 15))
                .foregroundColor(Color.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Presentation List
    private var presentationListView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(savedPresentations, id: \.self) { url in
                    PresentationRow(url: url)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            HapticManager.shared.impact(style: .light)
                            selectedPresentation = url
                        }
                        .contextMenu {
                            Button {
                                sharePresentation(url)
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }

                            Button(role: .destructive) {
                                presentationToDelete = url
                                showDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(20)
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
                .font(.system(size: 24))
                .foregroundColor(Color(red: 59/255, green: 130/255, blue: 246/255))
                .frame(width: 50, height: 50)
                .background(Color(red: 59/255, green: 130/255, blue: 246/255).opacity(0.15))
                .cornerRadius(10)

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(url.deletingPathExtension().lastPathComponent)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    if let date = fileDate {
                        Text(date, style: .date)
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.6))
                    }

                    if let size = fileSize {
                        Text("•")
                            .foregroundColor(Color.white.opacity(0.6))
                        Text(size)
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.6))
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(Color.white.opacity(0.4))
        }
        .padding(16)
        .background(Color(red: 28/255, green: 32/255, blue: 42/255))
        .cornerRadius(12)
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
