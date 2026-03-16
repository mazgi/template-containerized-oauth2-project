#if DEBUG
import SwiftUI

struct DebugSettingsView: View {
    @State private var apiBaseURL: String
    @Environment(\.dismiss) private var dismiss

    init() {
        _apiBaseURL = State(initialValue: UserDefaults.standard.string(forKey: "debug_api_base_url") ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("API Base URL") {
                    TextField("http://localhost:4000", text: $apiBaseURL)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                        .autocorrectionDisabled()
                }
                Section {
                    Text("Leave empty to use the default URL.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Debug Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = apiBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.isEmpty {
                            UserDefaults.standard.removeObject(forKey: "debug_api_base_url")
                        } else {
                            UserDefaults.standard.set(trimmed, forKey: "debug_api_base_url")
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}
#endif
