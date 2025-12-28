//
//  VolvoCarsAPICLT.swift
//  VolvoCarsAPI
//
//  Created by William Alexander on 23/12/2025.
//

import ArgumentParser
import Foundation
import VolvoCarsAPI

@main
struct VolvoCarsAPICLT: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        abstract: "A command-line tool to interact with Volvo Connected Car API.",
        version: "1.0.0",
        subcommands: [
            Authorize.self,
            Authenticate.self,
            ListVehicles.self,
            VehicleDetails.self,
            Odometer.self,
            Tyres.self,
            Logout.self
        ]
    )

    struct Options: ParsableArguments {
        @Option(help: ArgumentHelp("Your Volvo Developer Portal Client ID."))
        var clientID: String

        @Option(help: ArgumentHelp("Your Volvo Developer Portal Client Secret."))
        var clientSecret: String

        @Option(help: ArgumentHelp("Your Volvo Developer Portal VCC API Key."))
        var apiKey: String

        @Flag(help: ArgumentHelp("Enable verbose logging."))
        var verbose: Bool = false
    }
}

// MARK: - Authorize Command

extension VolvoCarsAPICLT {

    struct Authorize: AsyncParsableCommand {

        static let configuration = CommandConfiguration(
            abstract: "Get the authorization URL to start the OAuth flow."
        )

        @OptionGroup()
        var options: Options

        func run() async throws {
            let volvo = VolvoCarsAPI(
                clientID: options.clientID,
                clientSecret: options.clientSecret,
                apiKey: options.apiKey,
                isDebugLoggingEnabled: options.verbose
            )

            let authURL = try volvo.getAuthorizationURL()

            print("""

            Authorization Required
            =====================

            1. Open this URL in your browser:

               \(authURL.absoluteString)

            2. Log in with your Volvo account credentials

            3. After authorization, you'll be redirected to a URL like:
               volvocars://oauth-callback?code=AUTHORIZATION_CODE

            4. Copy the authorization code and run:
               volvo-connect authenticate --client-id \(options.clientID) --client-secret \(options.clientSecret) --api-key \(options.apiKey) --code AUTHORIZATION_CODE

            """)
        }
    }
}

// MARK: - Authenticate Command

extension VolvoCarsAPICLT {

    struct Authenticate: AsyncParsableCommand {

        static let configuration = CommandConfiguration(
            abstract: "Exchange authorization code for access token."
        )

        @OptionGroup()
        var options: Options

        @Option(help: ArgumentHelp("The authorization code from the redirect URL."))
        var code: String

        func run() async throws {
            let volvo = VolvoCarsAPI(
                clientID: options.clientID,
                clientSecret: options.clientSecret,
                apiKey: options.apiKey,
                isDebugLoggingEnabled: options.verbose,
                authStore: FileAuthStore(),
                storageKey: "volvo-cli-token"
            )

            print("Exchanging authorization code for access token...")

            try await volvo.authenticate(code: code)

            print("✓ Authentication successful!")
            print("Token automatically saved.")
            print("You can now use other commands to interact with your vehicles.")
        }
    }
}

// MARK: - List Vehicles Command

extension VolvoCarsAPICLT {

    struct ListVehicles: AsyncParsableCommand {

        static let configuration = CommandConfiguration(
            commandName: "list-vehicles",
            abstract: "List all vehicles in your account."
        )

        @OptionGroup()
        var options: Options

        func run() async throws {
            let volvo = try await createAuthenticatedClient()
            let vins = try await volvo.getVehicles()

            print("\nVehicles (\(vins.count)):")
            print("=" + String(repeating: "=", count: 40))

            if vins.isEmpty {
                print("No vehicles found.")
            } else {
                for (index, vin) in vins.enumerated() {
                    print("\(index + 1). \(vin)")
                }
            }
            print()
        }

        private func createAuthenticatedClient() async throws -> VolvoCarsAPI {
            let authStore = FileAuthStore()

            let volvo = VolvoCarsAPI(
                clientID: options.clientID,
                clientSecret: options.clientSecret,
                apiKey: options.apiKey,
                isDebugLoggingEnabled: options.verbose,
                authStore: authStore,
                storageKey: "volvo-cli-token"
            )

            // Check if token exists
            if await authStore.authentication(for: "volvo-cli-token") == nil {
                print("""
                ✗ No saved token found.

                Please authenticate first by running:
                1. volvo-connect authorize --client-id YOUR_CLIENT_ID --client-secret YOUR_CLIENT_SECRET --api-key YOUR_API_KEY
                2. Follow the instructions to get an authorization code
                3. volvo-connect authenticate --client-id YOUR_CLIENT_ID --client-secret YOUR_CLIENT_SECRET --api-key YOUR_API_KEY --code YOUR_CODE
                """)
                throw ExitCode.failure
            }

            return volvo
        }
    }
}

// MARK: - Vehicle Details Command

extension VolvoCarsAPICLT {

    struct VehicleDetails: AsyncParsableCommand {

        static let configuration = CommandConfiguration(
            commandName: "vehicle-details",
            abstract: "Get detailed information about a specific vehicle."
        )

        @OptionGroup()
        var options: Options

        @Argument(help: ArgumentHelp("The VIN of the vehicle."))
        var vin: String

        func run() async throws {
            let volvo = try await createAuthenticatedClient()
            let details = try await volvo.getVehicleDetails(vin: vin)

            print("\nVehicle Details:")
            print("=" + String(repeating: "=", count: 40))
            print("VIN:        \(details.vin)")
            print("Model:      \(details.descriptions?.model ?? "N/A")")
            print("Year:       \(details.modelYear.map(String.init) ?? "N/A")")
            if let imageURL = details.images?.exterior?.imageUrl {
                print("Image URL:  \(imageURL)")
            }
            print()
        }

        private func createAuthenticatedClient() async throws -> VolvoCarsAPI {
            let authStore = FileAuthStore()

            let volvo = VolvoCarsAPI(
                clientID: options.clientID,
                clientSecret: options.clientSecret,
                apiKey: options.apiKey,
                isDebugLoggingEnabled: options.verbose,
                authStore: authStore,
                storageKey: "volvo-cli-token"
            )

            // Check if token exists
            if await authStore.authentication(for: "volvo-cli-token") == nil {
                print("✗ No saved token found. Please authenticate first.")
                throw ExitCode.failure
            }

            return volvo
        }
    }
}

// MARK: - Odometer Command

extension VolvoCarsAPICLT {

    struct Odometer: AsyncParsableCommand {

        static let configuration = CommandConfiguration(
            abstract: "Get the odometer reading for a specific vehicle."
        )

        @OptionGroup()
        var options: Options

        @Argument(help: ArgumentHelp("The VIN of the vehicle."))
        var vin: String

        func run() async throws {
            let volvo = try await createAuthenticatedClient()

            if let odometer = try await volvo.getOdometer(vin: vin) {
                print("\nOdometer Reading:")
                print("=" + String(repeating: "=", count: 40))
                print("Value:      \(odometer.value) \(odometer.unit)")
                if let timestamp = odometer.timestamp {
                    print("Timestamp:  \(timestamp)")
                }
                print()
            } else {
                print("✗ No odometer data available for this vehicle.")
            }
        }

        private func createAuthenticatedClient() async throws -> VolvoCarsAPI {
            let authStore = FileAuthStore()

            let volvo = VolvoCarsAPI(
                clientID: options.clientID,
                clientSecret: options.clientSecret,
                apiKey: options.apiKey,
                isDebugLoggingEnabled: options.verbose,
                authStore: authStore,
                storageKey: "volvo-cli-token"
            )

            // Check if token exists
            if await authStore.authentication(for: "volvo-cli-token") == nil {
                print("✗ No saved token found. Please authenticate first.")
                throw ExitCode.failure
            }

            return volvo
        }
    }
}

// MARK: - Tyres Command

extension VolvoCarsAPICLT {

    struct Tyres: AsyncParsableCommand {

        static let configuration = CommandConfiguration(
            abstract: "Get the tyre status for a specific vehicle."
        )

        @OptionGroup()
        var options: Options

        @Argument(help: ArgumentHelp("The VIN of the vehicle."))
        var vin: String

        func run() async throws {
            let volvo = try await createAuthenticatedClient()
            let tyres = try await volvo.getTyres(vin: vin)

            print("\nTyre Status:")
            print("=" + String(repeating: "=", count: 40))
            print("\nFront Left:")
            print("  Status:     \(formatPressureLevel(tyres.frontLeft.value))")
            print("  Timestamp:  \(tyres.frontLeft.timestamp)")

            print("\nFront Right:")
            print("  Status:     \(formatPressureLevel(tyres.frontRight.value))")
            print("  Timestamp:  \(tyres.frontRight.timestamp)")

            print("\nRear Left:")
            print("  Status:     \(formatPressureLevel(tyres.rearLeft.value))")
            print("  Timestamp:  \(tyres.rearLeft.timestamp)")

            print("\nRear Right:")
            print("  Status:     \(formatPressureLevel(tyres.rearRight.value))")
            print("  Timestamp:  \(tyres.rearRight.timestamp)")
            print()
        }

        private func formatPressureLevel(_ level: TyresResponse.TyresData.TyreStatus.PressureLevel) -> String {
            switch level {
            case .unspecified:
                return "Unspecified"
            case .noWarning:
                return "✓ No Warning"
            case .veryLowPressure:
                return "⚠ Very Low Pressure"
            case .lowPressure:
                return "⚠ Low Pressure"
            case .highPressure:
                return "⚠ High Pressure"
            }
        }

        private func createAuthenticatedClient() async throws -> VolvoCarsAPI {
            let authStore = FileAuthStore()

            let volvo = VolvoCarsAPI(
                clientID: options.clientID,
                clientSecret: options.clientSecret,
                apiKey: options.apiKey,
                isDebugLoggingEnabled: options.verbose,
                authStore: authStore,
                storageKey: "volvo-cli-token"
            )

            // Check if token exists
            if await authStore.authentication(for: "volvo-cli-token") == nil {
                print("✗ No saved token found. Please authenticate first.")
                throw ExitCode.failure
            }

            return volvo
        }
    }
}

// MARK: - Logout Command

extension VolvoCarsAPICLT {

    struct Logout: AsyncParsableCommand {

        static let configuration = CommandConfiguration(
            abstract: "Remove saved authentication token."
        )

        func run() async throws {
            let authStore = FileAuthStore()

            if await authStore.authentication(for: "volvo-cli-token") != nil {
                try await authStore.storeAuthentication(token: nil, for: "volvo-cli-token")
                print("✓ Logged out successfully")
            } else {
                print("No saved token found")
            }
        }
    }
}
