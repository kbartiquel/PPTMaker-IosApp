//
//  APIService.swift
//  PPTMaker
//
//  Service for communicating with the backend API
//

import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case serverError(String)
    case invalidResponse
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}

class APIService {
    // Change this to your production URL when deployed
    #if DEBUG
    static let baseURL = "http://localhost:8000"
    #else
    static let baseURL = "https://your-render-app.onrender.com"
    #endif

    // MARK: - Step 1: Generate Outline
    func generateOutline(topic: String, numSlides: Int, tone: String? = nil, allowedSlideTypes: [String]? = nil) async throws -> PresentationOutline {
        guard let url = URL(string: "\(APIService.baseURL)/generate-outline") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = OutlineRequest(topic: topic, numSlides: numSlides, tone: tone, allowedSlideTypes: allowedSlideTypes)
        request.httpBody = try JSONEncoder().encode(requestBody)

        do {
            print("[DEBUG] Sending request to: \(url)")
            print("[DEBUG] Request body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "empty")")

            let (data, response) = try await URLSession.shared.data(for: request)

            print("[DEBUG] Received \(data.count) bytes")

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            print("[DEBUG] Status code: \(httpResponse.statusCode)")

            if httpResponse.statusCode == 200 {
                // Debug: Print raw response
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("[DEBUG] Response: \(jsonString.prefix(500))")
                }

                do {
                    let outlineResponse = try JSONDecoder().decode(OutlineResponse.self, from: data)
                    return outlineResponse.outline
                } catch let decodingError {
                    print("[ERROR] Decoding failed: \(decodingError)")
                    if let decodingError = decodingError as? DecodingError {
                        switch decodingError {
                        case .keyNotFound(let key, let context):
                            print("[ERROR] Missing key: \(key.stringValue) - \(context.debugDescription)")
                        case .typeMismatch(let type, let context):
                            print("[ERROR] Type mismatch: \(type) - \(context.debugDescription)")
                        case .valueNotFound(let type, let context):
                            print("[ERROR] Value not found: \(type) - \(context.debugDescription)")
                        case .dataCorrupted(let context):
                            print("[ERROR] Data corrupted: \(context.debugDescription)")
                        @unknown default:
                            print("[ERROR] Unknown decoding error")
                        }
                    }
                    throw APIError.decodingError(decodingError)
                }
            } else {
                // Try to parse error message
                if let errorDict = try? JSONDecoder().decode([String: String].self, from: data),
                   let detail = errorDict["detail"] {
                    throw APIError.serverError(detail)
                }
                throw APIError.serverError("HTTP \(httpResponse.statusCode)")
            }
        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - Step 2: Generate Presentation
    func generatePresentation(
        presentationTitle: String,
        slides: [SlideData],
        template: String
    ) async throws -> Data {
        guard let url = URL(string: "\(APIService.baseURL)/generate-presentation") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = PresentationRequest(
            presentationTitle: presentationTitle,
            slides: slides,
            template: template
        )
        request.httpBody = try JSONEncoder().encode(requestBody)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            if httpResponse.statusCode == 200 {
                return data
            } else {
                // Try to parse error message
                if let errorDict = try? JSONDecoder().decode([String: String].self, from: data),
                   let detail = errorDict["detail"] {
                    throw APIError.serverError(detail)
                }
                throw APIError.serverError("HTTP \(httpResponse.statusCode)")
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - Get Templates
    func getTemplates() async throws -> [Template] {
        // Return static templates (they match the backend)
        return Template.templates
    }
}
