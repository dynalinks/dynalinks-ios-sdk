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

Set your Client API Key via environment variable in Xcode:
1. Edit Scheme → Run → Arguments → Environment Variables
2. Add `DYNALINKS_API_KEY` with your key from the Dynalinks console

## Testing

1. Create a test link in the Dynalinks console with deferred deep linking enabled

2. Visit the link preview page in Safari on the simulator

3. Tap the App Store button (this records the fingerprint)

4. Open the example app and tap "Check for Deferred Deep Link"

5. If everything is configured correctly, you should see the match result!

## Features

- **Check for Deferred Deep Link**: Calls the SDK to match fingerprints
- **Reset SDK State**: Clears cached result to allow re-checking
- **Result Display**: Shows match confidence, score, and link details
