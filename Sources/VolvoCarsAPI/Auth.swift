//
//  Auth.swift
//  VolvoCarsAPI
//
//  Created by William Alexander on 23/12/2025.
//

import Foundation

final class Auth {

    private let authorizeURL = URL(string: "https://volvoid.eu.volvocars.com/as/authorization.oauth2")!
    private let tokenURL = URL(string: "https://volvoid.eu.volvocars.com/as/token.oauth2")!

    private var pkce: PKCE?
    private let authStore: AuthStoring
    private let storageKey: String

    private let clientID: String
    private let clientSecret: String
    private let redirectURI: String
    private let scopes: [String]
    private let urlSession: URLSession
    private let isDebugLoggingEnabled: Bool

    init(
        clientID: String,
        clientSecret: String,
        redirectURI: String = "volvocars://oauth-callback",
        scopes: [String] = [
            "openid",
            "conve:vehicle_relation",
            "conve:odometer_status"
        ],
        urlSession: URLSession,
        isDebugLoggingEnabled: Bool = false,
        authStore: AuthStoring? = nil,
        storageKey: String = "volvo-token"
    ) {
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.redirectURI = redirectURI
        self.scopes = scopes
        self.urlSession = urlSession
        self.isDebugLoggingEnabled = isDebugLoggingEnabled
        self.authStore = authStore ?? InMemoryAuthStore()
        self.storageKey = storageKey
    }

    /// Generates the authorization URL that the user needs to visit to authenticate
    func getAuthorizationURL(state: String? = nil) throws -> URL {
        let pkce = try PKCE()
        self.pkce = pkce

        var components = URLComponents(url: authorizeURL, resolvingAgainstBaseURL: false)
        var queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
            URLQueryItem(name: "code_challenge", value: pkce.codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]

        if let state = state {
            queryItems.append(URLQueryItem(name: "state", value: state))
        }

        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw VolvoAuthError.failedToConstructURL
        }

        return url
    }

    /// Exchanges the authorization code for access and refresh tokens
    func requestToken(code: String) async throws {
        guard let pkce = pkce else {
            throw VolvoAuthError.missingPKCE
        }

        let credentials = "\(clientID):\(clientSecret)"
        guard let credentialsData = credentials.data(using: .utf8) else {
            throw VolvoAuthError.invalidCredentials
        }
        let encodedCredentials = credentialsData.base64EncodedString()

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("Basic \(encodedCredentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectURI,
            "code_verifier": pkce.codeVerifier
        ]

        request.httpBody = bodyParams
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)

        if isDebugLoggingEnabled {
            AuthenticationLogger.debug("Requesting token with code")
        }

        let response: TokenResponse = try await urlSession.object(
            for: request,
            isDebugLoggingEnabled: isDebugLoggingEnabled
        )

        try await authStore.storeAuthentication(token: response, for: storageKey)

        if isDebugLoggingEnabled {
            AuthenticationLogger.debug("Token received successfully")
        }
    }

    /// Refreshes the access token using the refresh token
    func refreshToken() async throws {
        guard let currentToken = await authStore.authentication(for: storageKey) else {
            throw VolvoAuthError.noTokenAvailable
        }

        let credentials = "\(clientID):\(clientSecret)"
        guard let credentialsData = credentials.data(using: .utf8) else {
            throw VolvoAuthError.invalidCredentials
        }
        let encodedCredentials = credentialsData.base64EncodedString()

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("Basic \(encodedCredentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "grant_type": "refresh_token",
            "refresh_token": currentToken.refreshToken
        ]

        request.httpBody = bodyParams
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)

        if isDebugLoggingEnabled {
            AuthenticationLogger.debug("Refreshing token")
        }

        let response: TokenResponse = try await urlSession.object(
            for: request,
            isDebugLoggingEnabled: isDebugLoggingEnabled
        )

        try await authStore.storeAuthentication(token: response, for: storageKey)

        if isDebugLoggingEnabled {
            AuthenticationLogger.debug("Token refreshed successfully")
        }
    }

    /// Gets a valid access token, refreshing if necessary
    func getAccessToken() async throws -> String {
        guard let currentToken = await authStore.authentication(for: storageKey) else {
            throw VolvoAuthError.noTokenAvailable
        }

        let needsRefresh = currentToken.expiresAt < Date(timeIntervalSinceNow: 60)

        if needsRefresh {
            try await refreshToken()
        }

        guard let validToken = await authStore.authentication(for: storageKey) else {
            throw VolvoAuthError.noTokenAvailable
        }

        return validToken.accessToken
    }

    /// Sets an existing token (useful for restoring saved tokens)
    func setToken(_ token: TokenResponse) async {
        try? await authStore.storeAuthentication(token: token, for: storageKey)
    }

    /// Gets the current token (for saving/persistence)
    func getToken() async -> TokenResponse? {
        await authStore.authentication(for: storageKey)
    }
}

enum VolvoAuthError: Error, CustomStringConvertible {
    case failedToConstructURL
    case missingPKCE
    case invalidCredentials
    case noTokenAvailable

    var description: String {
        switch self {
        case .failedToConstructURL:
            return "Failed to construct authorization URL"
        case .missingPKCE:
            return "PKCE code verifier not found. Call getAuthorizationURL first"
        case .invalidCredentials:
            return "Invalid client credentials"
        case .noTokenAvailable:
            return "No token available. Authenticate first"
        }
    }
}
