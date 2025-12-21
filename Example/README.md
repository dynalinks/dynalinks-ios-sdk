# Dynalinks Example App

A simple iOS app demonstrating the Dynalinks SDK for deferred deep linking.

## Setup

```bash
cd Example
open DynalinksExample.xcodeproj
```

## Configuration

Edit `DynalinksExampleApp.swift` and replace the placeholder API key with your Client API Key from the Dynalinks console.

## Testing

1. Create a link in the Dynalinks console with deferred deep linking enabled
2. Visit the link preview page in Safari on the simulator
3. Tap the App Store button
4. Open the example app and tap "Check for Deferred Deep Link"
5. You should see the match result with confidence score and link details

## Features

- **Check for Deferred Deep Link**: Checks if user clicked a Dynalinks link before installing
- **Reset SDK State**: Clears cached result to allow re-checking
- **Result Display**: Shows match confidence, score, and link details
