//
//  TokenResponse.swift
//  VolvoCarsAPI
//
//  Created by William Alexander on 23/12/2025.
//

import Foundation

public struct TokenResponse: Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: Int
    public let tokenType: String
    public let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case expiresAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try container.decode(String.self, forKey: .accessToken)
        refreshToken = try container.decode(String.self, forKey: .refreshToken)
        expiresIn = try container.decode(Int.self, forKey: .expiresIn)
        tokenType = try container.decode(String.self, forKey: .tokenType)

        // Calculate expiresAt from current time + expiresIn when decoding from API response
        // If expiresAt is already in the decoded data (from Keychain), use that instead
        if let storedExpiresAt = try? container.decode(Date.self, forKey: .expiresAt) {
            expiresAt = storedExpiresAt
        } else {
            expiresAt = Date(timeIntervalSinceNow: TimeInterval(expiresIn))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accessToken, forKey: .accessToken)
        try container.encode(refreshToken, forKey: .refreshToken)
        try container.encode(expiresIn, forKey: .expiresIn)
        try container.encode(tokenType, forKey: .tokenType)
        try container.encode(expiresAt, forKey: .expiresAt)
    }
}
