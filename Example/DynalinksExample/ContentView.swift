import SwiftUI
import DynalinksSDK

struct ContentView: View {
    @State private var status: String = "Ready to check for deferred deep link"
    @State private var result: DeepLinkResult?
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                statusSection
                resultSection
                actionButtons
                Spacer()
            }
            .padding()
            .navigationTitle("Dynalinks Example")
        }
    }

    // MARK: - Views

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Status")
                .font(.headline)

            Text(status)
                .font(.body)
                .foregroundColor(.secondary)

            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Result")
                .font(.headline)

            if let result = result {
                resultDetails(result)
            } else {
                Text("No result yet")
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    @ViewBuilder
    private func resultDetails(_ result: DeepLinkResult) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Matched:")
                Spacer()
                Text(result.matched ? "Yes" : "No")
                    .foregroundColor(result.matched ? .green : .red)
                    .fontWeight(.semibold)
            }

            if let confidence = result.confidence {
                HStack {
                    Text("Confidence:")
                    Spacer()
                    Text(confidence.rawValue.capitalized)
                        .foregroundColor(confidenceColor(confidence))
                }
            }

            if let score = result.matchScore {
                HStack {
                    Text("Score:")
                    Spacer()
                    Text("\(score)%")
                }
            }

            if let link = result.link {
                Divider()
                    .padding(.vertical, 4)

                Text("Link Details")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                linkDetail("ID", link.id)
                linkDetail("Name", link.name)
                linkDetail("Path", link.path)
                linkDetail("Deep Link Value", link.deepLinkValue)
                linkDetail("URL", link.url?.absoluteString)
                linkDetail("Full URL", link.fullURL?.absoluteString)
                linkDetail("iOS Deferred Deep Linking", link.iosDeferredDeepLinkingEnabled == true ? "Enabled" : "Disabled")
            }
        }
        .font(.body)
    }

    private func linkDetail(_ label: String, _ value: String?) -> some View {
        Group {
            if let value = value {
                HStack(alignment: .top) {
                    Text("\(label):")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(value)
                        .multilineTextAlignment(.trailing)
                }
                .font(.caption)
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                Task { await checkForDeepLink() }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("Check for Deferred Deep Link")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isLoading)

            Button {
                resetSDK()
            } label: {
                Text("Reset SDK State")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
            }
        }
    }

    // MARK: - Actions

    private func checkForDeepLink() async {
        isLoading = true
        status = "Checking..."
        error = nil

        do {
            let deepLinkResult = try await Dynalinks.checkForDeferredDeepLink()
            result = deepLinkResult

            if deepLinkResult.matched {
                status = "Match found!"
            } else {
                status = "No match"
            }
        } catch let dynalinksError as DynalinksError {
            handleError(dynalinksError)
        } catch {
            status = "Error"
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func handleError(_ error: DynalinksError) {
        switch error {
        case .alreadyChecked:
            status = "Already checked"
            self.error = "Use 'Reset SDK State' to check again"
        case .simulator:
            status = "Simulator not allowed"
            self.error = "Enable allowSimulator in configuration"
        case .noMatch:
            status = "No match found"
            self.error = nil
        case .notConfigured:
            status = "SDK not configured"
            self.error = "Call Dynalinks.configure() first"
        case .networkError(let underlying):
            status = "Network error"
            self.error = underlying?.localizedDescription ?? "Check your connection"
        case .serverError(let code, let message):
            status = "Server error (\(code))"
            self.error = message
        case .invalidResponse:
            status = "Invalid response"
            self.error = "Server returned unexpected data"
        }
    }

    private func resetSDK() {
        Dynalinks.reset()
        result = nil
        error = nil
        status = "SDK state reset - ready to check again"
    }

    private func confidenceColor(_ confidence: DeepLinkResult.Confidence) -> Color {
        switch confidence {
        case .high: return .green
        case .medium: return .orange
        case .low: return .red
        }
    }
}

#Preview {
    ContentView()
}
