//
//  AuthStoring.swift
//  VolvoCarsAPI
//
//  Created by William Alexander on 28/12/2025.
//

import Foundation

/// A type that is able to handle storage and retrieval of OAuth authentication tokens.
public protocol AuthStoring: Sendable {
    /// Stores an authentication token for the given key
    ///
    /// - Parameters:
    ///   - token: The token to store, or nil to clear the stored token
    ///   - key: The storage key identifier
    func storeAuthentication(token: TokenResponse?, for key: String) async throws

    /// Retrieves the stored authentication token for the given key
    ///
    /// - Parameter key: The storage key identifier
    /// - Returns: The stored token, or nil if no token exists
    func authentication(for key: String) async -> TokenResponse?
}
