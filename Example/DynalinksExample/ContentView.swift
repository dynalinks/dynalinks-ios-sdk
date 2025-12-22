import SwiftUI
import DynalinksSDK

struct ContentView: View {
    let result: DeepLinkResult?
    let error: Error?

    var body: some View {
        NavigationStack {
            List {
                if let error {
                    Section("Error") {
                        Text(error.localizedDescription)
                            .foregroundColor(.red)
                    }
                }

                if let result {
                    Section("Result") {
                        LabeledContent("Matched", value: result.matched ? "Yes" : "No")
                        if let confidence = result.confidence {
                            LabeledContent("Confidence", value: confidence.rawValue)
                        }
                        if let score = result.matchScore {
                            LabeledContent("Score", value: "\(score)%")
                        }
                    }

                    if let link = result.link {
                        Section("Link") {
                            LabeledContent("ID", value: link.id)
                            if let name = link.name {
                                LabeledContent("Name", value: name)
                            }
                            if let path = link.deepLinkValue {
                                LabeledContent("Deep Link", value: path)
                            }
                            if let url = link.fullURL {
                                LabeledContent("URL", value: url.absoluteString)
                            }
                        }
                    }
                } else if error == nil {
                    Section {
                        Text("Waiting for deep link...")
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button("Reset SDK") {
                        Dynalinks.reset()
                    }
                }
            }
            .navigationTitle("Dynalinks")
        }
    }
}

#Preview {
    ContentView(result: nil, error: nil)
}
