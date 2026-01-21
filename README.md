# Dynalinks iOS SDK

Swift SDK for Dynalinks deferred deep linking.

## Requirements

- iOS 16.0+
- Swift 5.7+
- Xcode 15.0+

## Installation

### CocoaPods

Add the following to your `Podfile`:

```ruby
pod 'DynalinksSDK', '~> 1.0'
```

Then run:

```bash
pod install
```

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/dynalinks/dynalinks-ios-sdk", from: "1.0.0")
]
```

Or in Xcode:
1. Go to **File > Add Package Dependencies**
2. Enter the repository URL: `https://github.com/dynalinks/dynalinks-ios-sdk`
3. Select the version and add to your target

## Quick Start

### 1. Configure the SDK

Configure the SDK as early as possible in your app's lifecycle.

```swift
import DynalinksSDK

@main
struct MyApp: App {
    init() {
        do {
            try Dynalinks.configure(clientAPIKey: "your-client-api-key")
        } catch {
            print("Failed to configure Dynalinks: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

Or in UIKit:

```swift
import DynalinksSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        do {
            try Dynalinks.configure(clientAPIKey: "your-client-api-key")
        } catch {
            print("Failed to configure Dynalinks: \(error)")
        }
        return true
    }
}
```

### 2. Check for Deferred Deep Links

Check for deferred deep links on first app launch:

```swift
import DynalinksSDK

struct ContentView: View {
    var body: some View {
        Text("Hello, World!")
            .task {
                await checkForDeferredDeepLink()
            }
    }

    private func checkForDeferredDeepLink() async {
        do {
            let result = try await Dynalinks.checkForDeferredDeepLink()

            if result.matched, let link = result.link {
                print("Matched! Confidence: \(result.confidence?.rawValue ?? "unknown")")
                print("Deep link value: \(link.deepLinkValue ?? "")")

                // Parse query params from URL if needed
                if let url = link.url,
                   let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                    print("Query params: \(components.queryItems ?? [])")
                }

                // Navigate to the deep link destination
                handleDeepLink(link)
            }
        } catch DynalinksError.simulator {
            print("Running on simulator - skipped")
        } catch {
            print("Error: \(error)")
        }
    }

    private func handleDeepLink(_ link: DeepLinkResult.LinkData) {
        // Route to appropriate screen based on link.deepLinkValue
        // Example: "/product/shoes" -> ProductView(id: "shoes")
    }
}
```

### Completion Handler API

For non-async contexts:

```swift
Dynalinks.checkForDeferredDeepLink { result in
    switch result {
    case .success(let deepLink):
        if deepLink.matched, let link = deepLink.link {
            handleDeepLink(link)
        }
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

### 3. Handle Universal Links

When your app is opened via a Universal Link (user already has the app installed), use `handleUniversalLink` to resolve the link and get the full link data:

**SwiftUI (with `onOpenURL`):**

```swift
@main
struct MyApp: App {
    init() {
        do {
            try Dynalinks.configure(clientAPIKey: "your-client-api-key")
        } catch {
            print("Failed to configure: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    Task {
                        await handleUniversalLink(url)
                    }
                }
        }
    }

    private func handleUniversalLink(_ url: URL) async {
        do {
            let result = try await Dynalinks.handleUniversalLink(url: url)
            if result.matched, let link = result.link {
                // Navigate to the deep link destination
                print("Deep link: \(link.deepLinkValue ?? "")")
            }
        } catch {
            print("Failed to resolve link: \(error)")
        }
    }
}
```

**UIKit (SceneDelegate):**

```swift
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard let url = userActivity.webpageURL else { return }

        Task {
            do {
                let result = try await Dynalinks.handleUniversalLink(url: url)
                if result.matched, let link = result.link {
                    // Navigate to destination
                }
            } catch {
                print("Error: \(error)")
            }
        }
    }
}
```

**Completion Handler:**

```swift
Dynalinks.handleUniversalLink(url: url) { result in
    switch result {
    case .success(let deepLink):
        if deepLink.matched, let link = deepLink.link {
            handleDeepLink(link)
        }
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

> **Note:** When `handleUniversalLink` is called, the SDK automatically skips any subsequent deferred deep link check since the user already has a direct link.

### Universal Links Setup

For Universal Links to work, you need to configure Associated Domains in your app. See the [iOS Integration Guide](https://docs.dynalinks.app/integrations/ios.html) for setup instructions.

## Configuration Options

```swift
try Dynalinks.configure(
    // Required: Your client API key from the Dynalinks console
    clientAPIKey: "your-client-api-key",

    // Custom API URL (optional, defaults to production)
    baseURL: URL(string: "https://dynalinks.app/api/v1")!,

    // Log level (optional)
    // .debug - All logs (default in DEBUG builds)
    // .info  - Info, warnings, and errors
    // .warning - Warnings and errors
    // .error - Errors only (default in RELEASE builds)
    // .none  - No logging
    logLevel: .debug,

    // Allow checks on simulator (optional, defaults to false)
    // Useful for development/testing
    allowSimulator: true
)
```

## How It Works

### Universal Links (App Already Installed)

When a user clicks a Dynalinks link and your app is already installed:

1. **User clicks a Dynalinks link** → iOS opens your app directly
2. **App receives URL via `onOpenURL` or SceneDelegate**
3. **App calls `handleUniversalLink(url:)`** → SDK resolves link data
4. **App navigates to deep link destination**

### Deferred Deep Links (App Not Yet Installed)

When a user clicks a Dynalinks link but needs to install your app first:

1. **User clicks a Dynalinks link** → Opens web preview page
2. **Web page collects fingerprint** → Screen size, OS version, timezone, etc.
3. **User installs app from App Store**
4. **App calls `checkForDeferredDeepLink()`** → SDK collects device fingerprint
5. **Server matches fingerprints** → Returns the original link if matched
6. **App navigates to deep link destination**

> **Note:** If `handleUniversalLink` is called first, subsequent calls to `checkForDeferredDeepLink` will skip the server request since the user already has a direct link.

## DeepLinkResult

```swift
public struct DeepLinkResult {
    /// Whether a matching link was found
    public let matched: Bool

    /// Confidence level: .high, .medium, or .low
    public let confidence: Confidence?

    /// Match score (0-100)
    public let matchScore: Int?

    /// Link data if matched
    public let link: LinkData?
}

public struct LinkData {
    public let id: String                        // Link UUID
    public let name: String?                     // Link name
    public let path: String?                     // Path component
    public let shortenedPath: String?            // Shortened path
    public let url: URL?                         // Original URL (with query params)
    public let fullURL: URL?                     // Full Dynalinks URL
    public let deepLinkValue: String?            // Deep link value for routing
    public let iosDeferredDeepLinkingEnabled: Bool?

    // Attribution fields
    public let referrer: String?                 // Referrer tracking parameter
    public let providerToken: String?            // Apple Search Ads token (pt)
    public let campaignToken: String?            // Campaign identifier (ct)

    // ... additional fields for social sharing, fallback URLs, etc.
}
```

> **Note:** Query parameters are included in the `url` field. Parse them using `URLComponents`:
> ```swift
> if let url = link.url,
>    let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
>     let params = components.queryItems  // [URLQueryItem]
> }
> ```

## Error Handling

```swift
public enum DynalinksError: Error {
    case notConfigured              // SDK not configured
    case invalidAPIKey(String)      // API key is empty or invalid
    case simulator                  // Running on simulator (disabled by default)
    case networkError(underlying:)  // Network request failed
    case invalidResponse            // Server returned invalid response
    case noMatch                    // No matching link found
    case serverError(statusCode:, message:)  // Server returned error status
}
```

## Best Practices

1. **Call early**: Check for deferred deep links as early as possible after app launch
2. **Handle gracefully**: The SDK caches results - subsequent calls return cached data
3. **Don't block UI**: Use async/await or completion handlers
4. **Test on device**: Deferred deep linking is disabled on simulator by default

## Attribution Tracking

The SDK provides attribution data for campaign tracking and analytics:

```swift
let result = try await Dynalinks.checkForDeferredDeepLink()
if result.matched, let link = result.link {
    // Track attribution data for analytics
    if let referrer = link.referrer {
        print("Referrer: \(referrer)")  // e.g., "utm_source=facebook&utm_campaign=summer"
    }

    if let providerToken = link.providerToken {
        print("Apple Search Ads token: \(providerToken)")  // pt parameter
    }

    if let campaignToken = link.campaignToken {
        print("Campaign: \(campaignToken)")  // ct parameter
    }

    // Send to your analytics platform
    Analytics.track("deep_link_opened", properties: [
        "referrer": link.referrer,
        "provider_token": link.providerToken,
        "campaign": link.campaignToken,
        "deep_link": link.deepLinkValue
    ])
}
```

## Privacy

The SDK collects the following device information for fingerprint matching:

- Screen dimensions and scale
- iOS version
- Timezone and language settings
- Device model identifier
- App version and build number
- IDFV (Identifier for Vendor) - **No permission required**

**Note:** IDFV is different from IDFA and does not require App Tracking Transparency permission.

## SDK Version

You can access the current SDK version programmatically:

```swift
print("Dynalinks SDK version: \(Dynalinks.version)")  // e.g., "1.0.0"
```

## Running Tests

Tests must be run with xcodebuild (not `swift test`):

```bash
xcodebuild test -scheme DynalinksSDK -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation)'
```

## License

MIT License - see LICENSE file for details.
