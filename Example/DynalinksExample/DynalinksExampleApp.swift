import SwiftUI
import DynalinksSDK

@main
struct DynalinksExampleApp: App {
    @State private var deepLinkResult: DeepLinkResult?
    @State private var error: Error?

    init() {
        let apiKey = ProcessInfo.processInfo.environment["DYNALINKS_API_KEY"] ?? "00000000-0000-0000-0000-000000000000"
        let baseURLString = ProcessInfo.processInfo.environment["DYNALINKS_BASE_URL"] ?? "https://dynalinks.app/api/v1"

        do {
            try Dynalinks.configure(
                clientAPIKey: apiKey,
                baseURL: URL(string: baseURLString)!,
                logLevel: .debug,
                allowSimulator: true
            )
        } catch {
            print("Failed to configure Dynalinks SDK: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(result: deepLinkResult, error: error)
                .onOpenURL { url in
                    Task {
                        do {
                            deepLinkResult = try await Dynalinks.handleUniversalLink(url: url)
                            error = nil
                        } catch {
                            self.error = error
                        }
                    }
                }
                .task {
                    // Check for deferred deep link on first launch
                    do {
                        deepLinkResult = try await Dynalinks.checkForDeferredDeepLink()
                    } catch {
                        self.error = error
                    }
                }
        }
    }
}
