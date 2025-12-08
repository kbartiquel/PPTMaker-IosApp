//
//  PresentationHistoryView.swift
//  PPTMaker
//
//  View for browsing and managing saved presentations
//

import SwiftUI
import QuickLook

struct PresentationHistoryView: View {
    @ObservedObject var viewModel: PresentationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var savedPresentations: [URL] = []
    @State private var presentationsWithOutlines: Set<URL> = []
    @State private var selectedPresentation: URL?
    @State private var showDeleteAlert = false
    @State private var presentationToDelete: URL?
    @AppStorage("isDarkMode") private var isDarkMode = false

    private let fileService = FileService()
    private let apiService = APIService()

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
            .toolbarColorScheme(isDarkMode ? .dark : .light, for: .navigationBar)
            .toolbarBackground(backgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        refreshList()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(textColor)
                    }
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
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
                .foregroundColor(secondaryTextColor.opacity(0.6))

            Text("No Presentations Yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(textColor)

            Text("Create your first presentation to see it here")
                .font(.system(size: 15))
                .foregroundColor(secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Presentation List
    private var presentationListView: some View {
        List {
            ForEach(savedPresentations, id: \.self) { url in
                PresentationRow(
                    url: url,
                    cardColor: cardColor,
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor
                )
                .listRowBackground(backgroundColor)
                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                .contentShape(Rectangle())
                .onTapGesture {
                    HapticManager.shared.impact(style: .light)
                    selectedPresentation = url
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    // Only show Edit & Regenerate if outline JSON exists
                    if presentationsWithOutlines.contains(url) {
                        Button {
                            editAndRegenerate(url)
                        } label: {
                            Label("Edit & Regenerate", systemImage: "pencil.circle")
                        }
                        .tint(Color.brandPrimary)
                    }
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
                    .tint(Color.brandPrimary)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Actions
    private func refreshList() {
        savedPresentations = fileService.listSavedPresentations()

        // Check which presentations have outlines
        presentationsWithOutlines = Set(savedPresentations.filter { url in
            fileService.loadOutline(for: url) != nil
        })
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

    private func editAndRegenerate(_ url: URL) {
        HapticManager.shared.impact(style: .medium)
        viewModel.loadOutlineFromHistory(pptxURL: url)
        dismiss()
    }

    private func sharePresentation(_ url: URL) {
        HapticManager.shared.impact(style: .medium)

        guard FileManager.default.fileExists(atPath: url.path) else {
            print("[Share] File not found at: \(url.path)")
            return
        }

        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )

        // Find the key window and top-most view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
              var topController = window.rootViewController else {
            print("[Share] Could not find root view controller")
            return
        }

        // Navigate to the top-most presented controller
        while let presented = topController.presentedViewController {
            topController = presented
        }

        // Configure for iPad
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = topController.view
            popoverController.sourceRect = CGRect(x: topController.view.bounds.midX, y: topController.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }

        topController.present(activityVC, animated: true)
    }
}

// MARK: - Presentation Row
struct PresentationRow: View {
    let url: URL
    let cardColor: Color
    let textColor: Color
    let secondaryTextColor: Color
    @State private var fileDate: Date?
    @State private var fileSize: String?

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: "doc.richtext.fill")
                .font(.system(size: 24))
                .foregroundColor(Color.brandPrimary)
                .frame(width: 50, height: 50)
                .background(Color.brandPrimary.opacity(0.15))
                .cornerRadius(10)

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(url.deletingPathExtension().lastPathComponent)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(textColor)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    if let date = fileDate {
                        Text(date, style: .date)
                            .font(.system(size: 12))
                            .foregroundColor(secondaryTextColor)
                    }

                    if let size = fileSize {
                        Text("•")
                            .foregroundColor(secondaryTextColor)
                        Text(size)
                            .font(.system(size: 12))
                            .foregroundColor(secondaryTextColor)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(secondaryTextColor.opacity(0.6))
        }
        .padding(16)
        .background(cardColor)
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

struct QuickLookPreview: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false

    private var backgroundColor: Color {
        isDarkMode ? Color(red: 18/255, green: 18/255, blue: 24/255) : Color(red: 245/255, green: 245/255, blue: 250/255)
    }

    private var textColor: Color {
        isDarkMode ? .white : Color(red: 30/255, green: 30/255, blue: 30/255)
    }

    var body: some View {
        NavigationView {
            QuickLookPreviewController(url: url)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Close") {
                            dismiss()
                        }
                        .foregroundColor(textColor)
                        .fontWeight(.semibold)
                    }
                }
                .toolbarColorScheme(isDarkMode ? .dark : .light, for: .navigationBar)
                .toolbarBackground(backgroundColor, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

struct QuickLookPreviewController: UIViewControllerRepresentable {
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
