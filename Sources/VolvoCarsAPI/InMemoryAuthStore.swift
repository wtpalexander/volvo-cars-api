//
//  InMemoryAuthStore.swift
//  VolvoCarsAPI
//
//  Created by William Alexander on 28/12/2025.
//

import Foundation

/// In-memory authentication storage (default behavior)
///
/// Tokens are stored in memory and will be lost when the application terminates.
/// This is the default storage mechanism if no custom `AuthStoring` implementation is provided.
public actor InMemoryAuthStore: AuthStoring {
    private var tokens: [String: TokenResponse] = [:]

    public init() {}

    public func storeAuthentication(token: TokenResponse?, for key: String) async throws {
        if let token = token {
            tokens[key] = token
        } else {
            tokens.removeValue(forKey: key)
        }
    }

    public func authentication(for key: String) async -> TokenResponse? {
        tokens[key]
    }
}
