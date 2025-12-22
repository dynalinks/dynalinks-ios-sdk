# Dynalinks Example App

A simple iOS app demonstrating the Dynalinks SDK.

## Setup

1. Open the project:
   ```bash
   cd Example
   open DynalinksExample.xcodeproj
   ```

2. Set your API key in Xcode scheme environment variables:
   - Edit Scheme → Run → Arguments → Environment Variables
   - Add `DYNALINKS_API_KEY` = your client API key from Dynalinks console
   - Add `DYNALINKS_BASE_URL` = your API URL (optional, defaults to production)

## Universal Links Setup

For Universal Links to open the app directly:

1. **Configure your iOS app in Dynalinks console:**
   - Go to your project → iOS Apps
   - Add your app with Bundle ID and Team ID

2. **Update the entitlements file** (`DynalinksExample.entitlements`):
   ```xml
   <key>com.apple.developer.associated-domains</key>
   <array>
       <string>applinks:yourproject.dynalinks.app</string>
   </array>
   ```

3. **Sign the app** with your Apple Developer account (required for Associated Domains)

## Testing

### Universal Links (app installed)
1. Create a link in Dynalinks console
2. Open the link URL in Safari on your device
3. The app should open automatically via `onOpenURL`

### Deferred Deep Links (app not installed)
1. Create a link with deferred deep linking enabled
2. Visit the link in Safari (don't have app installed)
3. Install and open the app
4. The SDK automatically checks for deferred deep link on launch

## Features

- **Universal Link handling**: Opens links directly when app is installed
- **Deferred Deep Link**: Matches user after install via fingerprinting
- **Reset SDK**: Clears cached result to allow re-checking
