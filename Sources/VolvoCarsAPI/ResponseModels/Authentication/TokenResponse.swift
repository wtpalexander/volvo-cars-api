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

    public var expiresAt: Date {
        Date(timeIntervalSinceNow: TimeInterval(expiresIn))
    }

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}
