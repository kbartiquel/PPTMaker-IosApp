//
//  FileService.swift
//  PPTMaker
//
//  Service for saving and managing presentation files
//

import Foundation

class FileService {
    // MARK: - Save Presentation
    func savePresentation(_ data: Data, filename: String) throws -> URL {
        let documentsDirectory = getDocumentsDirectory()
        let fileURL = documentsDirectory.appendingPathComponent(filename)

        try data.write(to: fileURL)
        return fileURL
    }

    // MARK: - Get Documents Directory
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // MARK: - List Saved Presentations
    func listSavedPresentations() -> [URL] {
        let documentsDirectory = getDocumentsDirectory()

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: documentsDirectory,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )

            // Filter for .pptx files and sort by date (newest first)
            let pptxFiles = fileURLs
                .filter { $0.pathExtension == "pptx" }
                .sorted { file1, file2 in
                    let date1 = (try? file1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                    let date2 = (try? file2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                    return date1 > date2
                }

            return pptxFiles
        } catch {
            print("Error listing presentations: \(error)")
            return []
        }
    }

    // MARK: - Delete Presentation
    func deletePresentation(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
        // Also delete the outline JSON if it exists
        try? deleteOutline(for: url)
    }

    // MARK: - Generate Filename
    func generateFilename(from title: String) -> String {
        // Sanitize title for filename
        let sanitized = title
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")

        let truncated = String(sanitized.prefix(50))
        let filename = truncated.isEmpty ? "Presentation" : truncated

        return "\(filename).pptx"
    }

    // MARK: - Save Outline JSON
    func saveOutline(_ outline: PresentationOutline, for pptxURL: URL) throws {
        let jsonURL = pptxURL.deletingPathExtension().appendingPathExtension("json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(outline)
        try jsonData.write(to: jsonURL)
    }

    // MARK: - Load Outline JSON
    func loadOutline(for pptxURL: URL) -> PresentationOutline? {
        let jsonURL = pptxURL.deletingPathExtension().appendingPathExtension("json")

        guard FileManager.default.fileExists(atPath: jsonURL.path) else {
            return nil
        }

        do {
            let jsonData = try Data(contentsOf: jsonURL)
            let decoder = JSONDecoder()
            let outline = try decoder.decode(PresentationOutline.self, from: jsonData)
            return outline
        } catch {
            print("Error loading outline: \(error)")
            return nil
        }
    }

    // MARK: - Delete Outline JSON
    func deleteOutline(for pptxURL: URL) throws {
        let jsonURL = pptxURL.deletingPathExtension().appendingPathExtension("json")
        if FileManager.default.fileExists(atPath: jsonURL.path) {
            try FileManager.default.removeItem(at: jsonURL)
        }
    }
}
