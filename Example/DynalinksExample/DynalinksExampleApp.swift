import SwiftUI
import DynalinksSDK

@main
struct DynalinksExampleApp: App {
    init() {
        // Configure SDK with your client API key
        // Get this from your Dynalinks console (must be a valid UUID)
        do {
            try Dynalinks.configure(
                clientAPIKey: "5020d84b-957c-4153-b4ed-62037cbad667",  // Replace with your actual API key
                // Local development server
                baseURL: URL(string: "http://lvh.me:3000/api/v1")!,
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
