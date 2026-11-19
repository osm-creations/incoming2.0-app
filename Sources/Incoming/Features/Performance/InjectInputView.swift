import SwiftUI

struct InjectInputView: View {
    @EnvironmentObject var session: AppSession
    @State private var userId = ""
    @State private var savedUserId = ""
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var loadError: String?
    @State private var saveError: String?
    @State private var didSave = false

    private var trimmedId: String { userId.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isValid: Bool {
        trimmedId.isEmpty || trimmedId.range(of: #"^[A-Za-z0-9_-]{1,128}$"#, options: .regularExpression) != nil
    }

    var body: some View {
        Form {
            if isLoading {
                ProgressView("Loading Inject settings…")
            } else if let loadError {
                Text(loadError)
                Button("Retry") { Task { await load() } }
            } else {
                Section {
                    TextField("Inject User ID", text: Binding(get: { userId }, set: { newValue in
                        userId = newValue
                        didSave = false
                        saveError = nil
                    }), prompt: Text("Enter ID"))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .disabled(isSaving)
                } header: {
                    Text("Inject User ID")
                } footer: {
                    Text("Enter your Inject User ID to enable Inject.")
                }

                if !isValid {
                    Text("Use up to 128 letters, numbers, hyphens or underscores.")
                        .foregroundStyle(.red)
                }
                Button(isSaving ? "Saving…" : "Save") { Task { await save() } }
                    .disabled(isSaving || !isValid || trimmedId == savedUserId)
                if let saveError {
                    Text(saveError).foregroundStyle(.red)
                } else if didSave {
                    Text(savedUserId.isEmpty ? "Inject is off." : "Inject User ID saved.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Inject Input")
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }
        do {
            let data: PrimaryClipData = try await session.authenticated("/api/v1/clip-configs/primary")
            savedUserId = data.config.injectUserId ?? ""
            userId = savedUserId
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func save() async {
        guard !isSaving, isValid else { return }
        isSaving = true
        saveError = nil
        didSave = false
        defer { isSaving = false }
        do {
            let data: PrimaryClipData = try await session.authenticated(
                "/api/v1/clip-configs/primary",
                method: "PATCH",
                body: AnyEncodable(PrimaryClipUpdateRequest(injectUserId: trimmedId))
            )
            savedUserId = data.config.injectUserId ?? ""
            userId = savedUserId
            didSave = true
        } catch APIClientError.server(_, "VALIDATION_ERROR", _) {
            saveError = "Use up to 128 letters, numbers, hyphens or underscores for the Inject User ID."
        } catch {
            saveError = error.localizedDescription
        }
    }
}
