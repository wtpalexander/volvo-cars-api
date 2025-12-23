//
//  VolvoCarsAPI.swift
//  VolvoCarsAPI
//
//  Created by William Alexander on 23/12/2025.
//

import Foundation

public final class VolvoCarsAPI: @unchecked Sendable {

    private let apiBaseURL = URL(string: "https://api.volvocars.com")!
    private let connectedVehicleEndpoint = "/connected-vehicle/v2/vehicles"

    private let auth: Auth
    private let apiKey: String
    private let urlSession: URLSession
    private let isDebugLoggingEnabled: Bool

    /// Initialize VolvoCarsAPI with OAuth2 credentials
    ///
    /// - Parameters:
    ///   - clientID: OAuth2 client ID from Volvo Developer Portal
    ///   - clientSecret: OAuth2 client secret from Volvo Developer Portal
    ///   - apiKey: VCC API key from Volvo Developer Portal
    ///   - redirectURI: OAuth2 redirect URI (default: volvocars://oauth-callback)
    ///   - scopes: OAuth2 scopes (default: openid, vehicle_relation, odometer_status)
    ///   - urlSession: URLSession to use for requests (default: .shared)
    ///   - isDebugLoggingEnabled: Enable debug logging (default: false)
    public init(
        clientID: String,
        clientSecret: String,
        apiKey: String,
        redirectURI: String = "volvocars://oauth-callback",
        scopes: [String] = [
            "openid",
            "conve:vehicle_relation",
            "conve:odometer_status"
        ],
        urlSession: URLSession = .shared,
        isDebugLoggingEnabled: Bool = false
    ) {
        self.auth = Auth(
            clientID: clientID,
            clientSecret: clientSecret,
            redirectURI: redirectURI,
            scopes: scopes,
            urlSession: urlSession,
            isDebugLoggingEnabled: isDebugLoggingEnabled
        )
        self.apiKey = apiKey
        self.urlSession = urlSession
        self.isDebugLoggingEnabled = isDebugLoggingEnabled
    }

    // MARK: - Authentication

    /// Generates the authorization URL for the user to authenticate
    ///
    /// The user should open this URL in a browser, authenticate, and then you can
    /// extract the authorization code from the redirect URL
    ///
    /// - Parameter state: Optional state parameter for CSRF protection
    /// - Returns: Authorization URL
    public func getAuthorizationURL(state: String? = nil) throws -> URL {
        try auth.getAuthorizationURL(state: state)
    }

    /// Exchanges the authorization code for access and refresh tokens
    ///
    /// - Parameter code: Authorization code from the redirect URL after user authentication
    public func authenticate(code: String) async throws {
        try await auth.requestToken(code: code)
    }

    /// Sets an existing token (useful for restoring saved tokens)
    ///
    /// - Parameter token: Previously saved token
    public func setToken(_ token: TokenResponse) async {
        await auth.setToken(token)
    }

    /// Gets the current token (for saving/persistence)
    ///
    /// - Returns: Current token if available
    public func getToken() async -> TokenResponse? {
        await auth.getToken()
    }

    // MARK: - Vehicles

    /// Gets the list of vehicles associated with the authenticated account
    ///
    /// Required scopes: openid conve:vehicle_relation
    ///
    /// - Returns: Array of vehicle VINs
    public func getVehicles() async throws -> [String] {
        let url = apiBaseURL.appending(path: connectedVehicleEndpoint)
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = try await headers()

        let response: VehiclesResponse = try await urlSession.object(
            for: request,
            isDebugLoggingEnabled: isDebugLoggingEnabled
        )

        return response.data.map { $0.vin }
    }

    /// Gets detailed information about a specific vehicle
    ///
    /// Required scopes: openid conve:vehicle_relation
    ///
    /// - Parameter vin: Vehicle Identification Number
    /// - Returns: Vehicle details
    public func getVehicleDetails(vin: String) async throws -> VehicleDetailsResponse.VehicleDetails {
        let url = apiBaseURL.appending(path: "\(connectedVehicleEndpoint)/\(vin)")
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = try await headers()

        let response: VehicleDetailsResponse = try await urlSession.object(
            for: request,
            isDebugLoggingEnabled: isDebugLoggingEnabled
        )

        return response.data
    }

    /// Gets the odometer reading for a specific vehicle
    ///
    /// Required scopes: openid conve:odometer_status
    ///
    /// - Parameter vin: Vehicle Identification Number
    /// - Returns: Odometer data including value and unit
    public func getOdometer(vin: String) async throws -> OdometerResponse.OdometerData.Odometer? {
        let url = apiBaseURL.appending(path: "\(connectedVehicleEndpoint)/\(vin)/odometer")
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = try await headers()

        let response: OdometerResponse = try await urlSession.object(
            for: request,
            isDebugLoggingEnabled: isDebugLoggingEnabled
        )

        return response.data.odometer
    }

    // MARK: - Private Helpers

    private func headers() async throws -> [String: String] {
        let accessToken = try await auth.getAccessToken()
        return [
            "Authorization": "Bearer \(accessToken)",
            "vcc-api-key": apiKey,
            "Content-Type": "application/json"
        ]
    }
}
