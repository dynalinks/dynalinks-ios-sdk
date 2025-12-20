import SwiftUI
import DynalinksSDK

@main
struct DynalinksExampleApp: App {
    init() {
        // Configure SDK with your client API key
        // Get this from your Dynalinks console (must be a valid UUID)
        do {
            try Dynalinks.configure(
                clientAPIKey: "00000000-0000-0000-0000-000000000000",  // Replace with your actual API key
                // Use your local development server for testing
                baseURL: URL(string: "http://localhost:3000/api/v1")!,
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
