//
//  TokenStorage.swift
//  VolvoCarsAPICLT
//
//  Created by William Alexander on 23/12/2025.
//

import Foundation
import VolvoCarsAPI

struct TokenStorage {

    private static let tokenFilePath: URL = {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        return homeDirectory.appendingPathComponent(".volvo-cars-api-token.json")
    }()

    static func save(_ token: TokenResponse) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(token)
        try data.write(to: tokenFilePath)
        print("Token saved to \(tokenFilePath.path)")
    }

    static func load() throws -> TokenResponse? {
        guard FileManager.default.fileExists(atPath: tokenFilePath.path) else {
            return nil
        }

        let data = try Data(contentsOf: tokenFilePath)
        let decoder = JSONDecoder()
        return try decoder.decode(TokenResponse.self, from: data)
    }

    static func delete() throws {
        guard FileManager.default.fileExists(atPath: tokenFilePath.path) else {
            return
        }
        try FileManager.default.removeItem(at: tokenFilePath)
        print("Token deleted")
    }

    static func exists() -> Bool {
        FileManager.default.fileExists(atPath: tokenFilePath.path)
    }
}
