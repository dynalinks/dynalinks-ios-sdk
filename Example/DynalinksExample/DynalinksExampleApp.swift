import SwiftUI
import DynalinksSDK

@main
struct DynalinksExampleApp: App {
    init() {
        // Configure SDK with your client API key
        // Get this from your Dynalinks console (must be a valid UUID)
        //
        // To override, set DYNALINKS_API_KEY environment variable in Xcode:
        // Edit Scheme → Run → Arguments → Environment Variables
        let apiKey = ProcessInfo.processInfo.environment["DYNALINKS_API_KEY"] ?? "00000000-0000-0000-0000-000000000000"
        let baseURLString = ProcessInfo.processInfo.environment["DYNALINKS_BASE_URL"] ?? "https://dynalinks.app/api/v1"

        do {
            try Dynalinks.configure(
                clientAPIKey: apiKey,
                baseURL: URL(string: baseURLString)!,
                logLevel: .debug,
                allowSimulator: true  // Enable for testing on simulator
            )
        } catch {
            print("Failed to configure Dynalinks SDK: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
