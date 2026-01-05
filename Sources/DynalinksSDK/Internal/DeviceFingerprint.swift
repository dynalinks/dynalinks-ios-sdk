import UIKit

/// Device fingerprint data collected for matching
struct DeviceFingerprint: Encodable {
    let screenWidth: Int
    let screenHeight: Int
    let devicePixelRatio: Double
    let osVersion: String
    let timezone: String
    let calendar: String
    let language: String
    let languages: [String]
    let countryCode: String?
    let deviceModel: String
    let idfv: String?
    let appVersion: String?
    let appBuild: String?
    let simulator: Bool

    enum CodingKeys: String, CodingKey {
        case screenWidth = "screen_width"
        case screenHeight = "screen_height"
        case devicePixelRatio = "device_pixel_ratio"
        case osVersion = "os_version"
        case timezone
        case calendar
        case language
        case languages
        case countryCode = "country_code"
        case deviceModel = "device_model"
        case idfv
        case appVersion = "app_version"
        case appBuild = "app_build"
        case simulator
    }

    /// Collect device fingerprint data
    static func collect() -> DeviceFingerprint {
        let screen = UIScreen.main
        let bounds = screen.bounds  // Use logical pixels to match web's screen.width/height
        let device = UIDevice.current
        let locale = Locale.current
        let bundle = Bundle.main

        return DeviceFingerprint(
            screenWidth: Int(bounds.width),
            screenHeight: Int(bounds.height),
            devicePixelRatio: Double(screen.scale),
            osVersion: normalizeOSVersion(device.systemVersion),
            timezone: TimeZone.current.identifier,
            calendar: calendarIdentifierForWeb(locale.calendar.identifier),
            language: Locale.preferredLanguages.first ?? "en",
            languages: Locale.preferredLanguages,
            countryCode: locale.region?.identifier,
            deviceModel: UIDevice.modelIdentifier,
            idfv: device.identifierForVendor?.uuidString,
            appVersion: bundle.infoDictionary?["CFBundleShortVersionString"] as? String,
            appBuild: bundle.infoDictionary?["CFBundleVersion"] as? String,
            simulator: isSimulator()
        )
    }

    /// Normalize OS version to X.Y.Z format
    /// Examples: "17" → "17.0.0", "17.0" → "17.0.0", "17.0.1" → "17.0.1"
    private static func normalizeOSVersion(_ version: String) -> String {
        var parts = version.split(separator: ".").map(String.init)
        while parts.count < 3 {
            parts.append("0")
        }
        return parts.prefix(3).joined(separator: ".")
    }

    /// Check if running on simulator
    private static func isSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    /// Convert Swift calendar identifier to web Intl API format (BCP 47)
    /// Swift uses ICU identifiers, JavaScript Intl uses BCP 47 Unicode extensions
    private static func calendarIdentifierForWeb(_ identifier: Calendar.Identifier) -> String {
        switch identifier {
        case .gregorian: return "gregory"  // ICU "gregorian" → BCP 47 "gregory"
        case .buddhist: return "buddhist"
        case .chinese: return "chinese"
        case .coptic: return "coptic"
        case .ethiopicAmeteMihret: return "ethiopic"
        case .ethiopicAmeteAlem: return "ethioaa"
        case .hebrew: return "hebrew"
        case .indian: return "indian"
        case .islamic: return "islamic"
        case .islamicCivil: return "islamic-civil"
        case .islamicTabular: return "islamic-tbla"
        case .islamicUmmAlQura: return "islamic-umalqura"
        case .japanese: return "japanese"
        case .persian: return "persian"
        case .republicOfChina: return "roc"
        case .iso8601: return "iso8601"
        @unknown default: return "gregory"
        }
    }
}
