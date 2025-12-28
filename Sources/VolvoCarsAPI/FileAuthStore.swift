//
//  FileAuthStore.swift
//  VolvoCarsAPI
//
//  Created by William Alexander on 28/12/2025.
//

import Foundation

/// File-based authentication storage
///
/// Stores tokens as JSON files in the file system. By default, tokens are stored
/// in the user's home directory as hidden files (`.{key}-token.json`).
///
/// Example:
/// ```swift
/// let authStore = FileAuthStore()
/// let api = VolvoCarsAPI(
///     clientID: "...",
///     clientSecret: "...",
///     apiKey: "...",
///     authStore: authStore
/// )
/// ```
public actor FileAuthStore: AuthStoring {
    private let baseDirectory: URL

    /// Creates a file-based auth store
    ///
    /// - Parameter baseDirectory: Directory to store token files (defaults to user's home directory)
    public init(baseDirectory: URL? = nil) {
        self.baseDirectory = baseDirectory ?? FileManager.default.homeDirectoryForCurrentUser
    }

    public func storeAuthentication(token: TokenResponse?, for key: String) async throws {
        let fileURL = tokenFileURL(for: key)

        if let token = token {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(token)
            try data.write(to: fileURL, options: .atomic)
        } else {
            // Delete token file if it exists
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
        }
    }

    public func authentication(for key: String) async -> TokenResponse? {
        let fileURL = tokenFileURL(for: key)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            return try decoder.decode(TokenResponse.self, from: data)
        } catch {
            // If we can't decode the token, return nil (corrupted file)
            return nil
        }
    }

    private func tokenFileURL(for key: String) -> URL {
        // Sanitize key to be filesystem-safe
        let sanitizedKey = key.replacingOccurrences(of: "/", with: "-")
        return baseDirectory.appendingPathComponent(".\(sanitizedKey)-token.json")
    }
}
