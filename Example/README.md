# Dynalinks Example App

A simple iOS app demonstrating the Dynalinks SDK for deferred deep linking.

## Setup

### Option 1: Using XcodeGen (Recommended)

If you have [XcodeGen](https://github.com/yonaskolb/XcodeGen) installed:

```bash
cd Example
xcodegen generate
open DynalinksExample.xcodeproj
```

### Option 2: Manual Xcode Project

1. Open Xcode
2. Create a new iOS App project:
   - Product Name: `DynalinksExample`
   - Interface: SwiftUI
   - Language: Swift
3. Delete the generated `ContentView.swift` and `DynalinksExampleApp.swift`
4. Drag in the files from `DynalinksExample/`:
   - `DynalinksExampleApp.swift`
   - `ContentView.swift`
5. Add the SDK package:
   - File > Add Package Dependencies
   - Click "Add Local..."
   - Select the `DynalinksSDK` folder (parent of Example)
6. Build and run

## Configuration

Edit `DynalinksExampleApp.swift` to configure your settings:

```swift
Dynalinks.configure(
    clientAPIKey: "your-client-api-key-here",  // From Dynalinks console
    baseURL: URL(string: "http://localhost:3000")!,  // Your server URL
    logLevel: .debug,
    allowSimulator: true  // For testing
)
```

## Testing

1. Start your Dynalinks server locally:
   ```bash
   cd /path/to/dynalinks
   bin/rails server
   ```

2. Create a test link in the console

3. Visit the link preview page in Safari on the simulator

4. Open the example app and tap "Check for Deferred Deep Link"

5. If everything is configured correctly, you should see the match result!

## Features

- **Check for Deferred Deep Link**: Calls the SDK to match fingerprints
- **Reset SDK State**: Clears cached result to allow re-checking
- **Result Display**: Shows match confidence, score, and link details
