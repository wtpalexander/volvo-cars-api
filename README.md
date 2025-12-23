# VolvoCarsAPI

A Swift package for accessing the Volvo Connected Car API.

## Features

- OAuth2 authentication with PKCE
- List vehicles in your account
- Get vehicle details
- Get odometer readings

## Requirements

- iOS 16.0+ / macOS 13.0+ / watchOS 9.0+ / tvOS 16.0+
- Swift 6.0+
- Volvo Developer Portal credentials (Client ID, Client Secret, and API Key)

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/volvo-cars-api.git", from: "1.0.0")
]
```

Or in Xcode, go to File > Add Package Dependencies and enter the repository URL.

## Setup

1. Register for a Volvo Developer account at https://developer.volvocars.com/
2. Create a new application in the Volvo Developer Portal
3. Note your Client ID, Client Secret, and VCC API Key
4. Configure your OAuth redirect URI (e.g., `volvocars://oauth-callback`)

## Command Line Tool

The package includes a command-line tool for easy testing and interaction with the Volvo API.

### Build the CLI

```bash
swift build
.build/debug/VolvoCarsAPICLT --help
```

### Authentication

1. Start the OAuth flow to get an authorization URL:

```bash
.build/debug/VolvoCarsAPICLT authorize \
  --client-id YOUR_CLIENT_ID \
  --client-secret YOUR_CLIENT_SECRET \
  --api-key YOUR_API_KEY
```

2. Open the displayed URL in your browser and log in with your Volvo account

3. After authorization, you'll be redirected to a URL like:
   `volvocars://oauth-callback?code=AUTHORIZATION_CODE`

4. Exchange the authorization code for an access token:

```bash
.build/debug/VolvoCarsAPICLT authenticate \
  --client-id YOUR_CLIENT_ID \
  --client-secret YOUR_CLIENT_SECRET \
  --api-key YOUR_API_KEY \
  --code AUTHORIZATION_CODE
```

The token will be saved to `~/.volvo-cars-api-token.json` and automatically used for subsequent commands.

### CLI Commands

**List all vehicles:**

```bash
.build/debug/VolvoCarsAPICLT list-vehicles \
  --client-id YOUR_CLIENT_ID \
  --client-secret YOUR_CLIENT_SECRET \
  --api-key YOUR_API_KEY
```

**Get vehicle details:**

```bash
.build/debug/VolvoCarsAPICLT vehicle-details YOUR_VIN \
  --client-id YOUR_CLIENT_ID \
  --client-secret YOUR_CLIENT_SECRET \
  --api-key YOUR_API_KEY
```

**Get odometer reading:**

```bash
.build/debug/VolvoCarsAPICLT odometer YOUR_VIN \
  --client-id YOUR_CLIENT_ID \
  --client-secret YOUR_CLIENT_SECRET \
  --api-key YOUR_API_KEY
```

**Enable verbose logging:**

Add the `--verbose` flag to any command:

```bash
.build/debug/VolvoCarsAPICLT list-vehicles \
  --client-id YOUR_CLIENT_ID \
  --client-secret YOUR_CLIENT_SECRET \
  --api-key YOUR_API_KEY \
  --verbose
```

**Logout (remove saved token):**

```bash
.build/debug/VolvoCarsAPICLT logout
```

## Usage as a Library

### Initialize VolvoCarsAPI

```swift
import VolvoCarsAPI

let volvo = VolvoCarsAPI(
    clientID: "your-client-id",
    clientSecret: "your-client-secret",
    apiKey: "your-vcc-api-key"
)
```

### Authentication Flow

Volvo uses OAuth2 with PKCE for authentication. The authentication flow requires user interaction:

```swift
// 1. Generate the authorization URL
let authURL = try volvo.getAuthorizationURL()

// 2. Open this URL in a browser for the user to authenticate
// The user will be redirected to your redirect URI with an authorization code

// 3. Extract the code from the redirect URL and exchange it for tokens
try await volvo.authenticate(code: authorizationCode)
```

### Persist Tokens

You can save and restore tokens to avoid requiring the user to authenticate each time:

```swift
// Save the token after authentication
if let token = await volvo.getToken() {
    // Save token to keychain or secure storage
    saveToken(token)
}

// Restore the token on next launch
if let savedToken = loadToken() {
    await volvo.setToken(savedToken)
}
```

### Get Vehicles

```swift
let vins = try await volvo.getVehicles()
print("Found \(vins.count) vehicles")
```

### Get Vehicle Details

```swift
let details = try await volvo.getVehicleDetails(vin: "YV1ABC123DEF45678")
print("Model: \(details.descriptions?.model ?? "Unknown")")
print("Year: \(details.modelYear ?? 0)")
```

### Get Odometer Reading

```swift
if let odometer = try await volvo.getOdometer(vin: "YV1ABC123DEF45678") {
    print("Odometer: \(odometer.value) \(odometer.unit)")
}
```

## OAuth Scopes

The package requests the following default scopes:
- `openid` - Required for authentication
- `conve:vehicle_relation` - List vehicles and get vehicle details
- `conve:odometer_status` - Read odometer values

You can customize the scopes when initializing VolvoCarsAPI:

```swift
let volvo = VolvoCarsAPI(
    clientID: "your-client-id",
    clientSecret: "your-client-secret",
    apiKey: "your-vcc-api-key",
    scopes: [
        "openid",
        "conve:vehicle_relation",
        "conve:odometer_status",
        "conve:fuel_status"
    ]
)
```

Available scopes can be found in the [Volvo API documentation](https://developer.volvocars.com/apis/connected-vehicle/overview/).

## Error Handling

The package throws errors for authentication failures and API errors:

```swift
do {
    let vehicles = try await volvo.getVehicles()
    print(vehicles)
} catch let error as VolvoAuthError {
    print("Authentication error: \(error)")
} catch {
    print("API error: \(error)")
}
```

## Debug Logging

Enable debug logging to see network requests and responses:

```swift
let volvo = VolvoCarsAPI(
    clientID: "your-client-id",
    clientSecret: "your-client-secret",
    apiKey: "your-vcc-api-key",
    isDebugLoggingEnabled: true
)
```

## License

This project is licensed under the GNU General Public License v3.0 - see the LICENSE file for details.

## Acknowledgments

- Based on the [volvocars-api](https://github.com/Realiserad/volvocars-api) Python library
- Uses the official [Volvo Cars API](https://developer.volvocars.com/)
