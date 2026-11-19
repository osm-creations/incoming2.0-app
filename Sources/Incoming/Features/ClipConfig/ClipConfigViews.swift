import SwiftUI
import UIKit

struct PrimaryClipSettingsView: View {
    @EnvironmentObject var session: AppSession

    private enum LoadState {
        case loading
        case ready(PrimaryClipData)
        case failed(String)
    }

    @State private var loadState: LoadState = .loading
    @State private var draftText = ""
    @State private var savedText = ""
    @State private var callerName = ""
    @State private var savedCallerName = ""
    @State private var isSaving = false
    @State private var copied = false
    @State private var alertMessage: String?
    @StateObject private var nfc = NFCWriterService()

    var body: some View {
        ZStack {
            IncomingTheme.background.ignoresSafeArea()

            switch loadState {
            case .loading:
                VStack(spacing: 14) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Loading App Clip settings…")
                        .font(.headline)
                    Text("This should only take a moment.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

            case .failed(let message):
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 34))
                        .foregroundStyle(.yellow)
                    Text("Couldn't load App Clip settings")
                        .font(.title3.bold())
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Button("Retry") {
                        Task { await load() }
                    }
                    .buttonStyle(IncomingButtonStyle(prominent: true))
                    .padding(.horizontal, 36)
                }

            case .ready(let data):
                ScrollView {
                    VStack(spacing: 18) {
                        IncomingCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Force word or note", systemImage: "text.cursor")
                                    .font(.headline)

                                TextEditor(text: $draftText)
                                    .frame(minHeight: 105, maxHeight: 150)
                                    .scrollContentBackground(.hidden)
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.black.opacity(0.25))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                                    )

                                Text("This text appears when the App Clip opens Notes.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                                Label("Caller name", systemImage: "phone.fill")
                                    .font(.headline)
                                TextField("Name shown on the call", text: $callerName)
                                    .textFieldStyle(.roundedBorder)
                                    .textInputAutocapitalization(.words)
                                Text("Leave this blank to display Unknown.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                                if draftText.utf16.count > 500 || callerName.utf16.count > 120 {
                                    Text("Notes can contain up to 500 characters and caller names up to 120.")
                                        .font(.footnote)
                                        .foregroundStyle(.red)
                                }

                                Button {
                                    Task { await save() }
                                } label: {
                                    HStack {
                                        if isSaving {
                                            ProgressView()
                                                .tint(.white)
                                        }
                                        Text(isSaving ? "Saving…" : "Set & Save")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(IncomingButtonStyle(prominent: true))
                                .disabled(
                                    isSaving || (draftText == savedText && callerName == savedCallerName)
                                        || draftText.utf16.count > 500 || callerName.utf16.count > 120
                                )
                            }
                            .disabled(isSaving)
                        }

                        IncomingCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Saved note")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)

                                Text(savedText.isEmpty ? "Not set" : savedText)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(savedText.isEmpty ? .secondary : .primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("Saved caller name")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Text(savedCallerName.isEmpty ? "Unknown" : savedCallerName)
                            }
                        }

                        IncomingCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("App Clip Link", systemImage: "link")
                                    .font(.headline)

                                Button {
                                    UIPasteboard.general.string = data.invocationUrl
                                    copied = true
                                    Task { @MainActor in
                                        try? await Task.sleep(for: .seconds(1.2))
                                        copied = false
                                    }
                                } label: {
                                    Label(copied ? "Copied" : "Copy Link", systemImage: copied ? "checkmark" : "doc.on.doc")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(IncomingButtonStyle(prominent: false))

                                Button {
                                    if let url = URL(string: data.invocationUrl) {
                                        nfc.write(url: url)
                                    }
                                } label: {
                                    Label("Write NFC Tag", systemImage: "wave.3.right")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(IncomingButtonStyle(prominent: false))

                                Text(data.invocationUrl)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: 620)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("App Clip Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .alert(
            "Incoming",
            isPresented: Binding(
                get: { alertMessage != nil },
                set: { if !$0 { alertMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
        .alert(
            "NFC",
            isPresented: Binding(
                get: { nfc.message != nil },
                set: { if !$0 { nfc.message = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(nfc.message ?? "")
        }
    }

    private func load() async {
        loadState = .loading
        do {
            let loaded: PrimaryClipData = try await session.authenticated("/api/v1/clip-configs/primary")
            let serverText = loaded.config.staticText ?? ""
            draftText = serverText
            savedText = serverText
            callerName = loaded.config.callerName ?? ""
            savedCallerName = callerName
            loadState = .ready(loaded)
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    private func save() async {
        guard case .ready = loadState, !isSaving else { return }

        isSaving = true
        defer { isSaving = false }

        do {
            let updated: PrimaryClipData = try await session.authenticated(
                "/api/v1/clip-configs/primary",
                method: "PATCH",
                body: AnyEncodable(PrimaryClipUpdateRequest(
                    staticText: draftText == savedText ? nil : draftText,
                    callerName: callerName == savedCallerName ? nil : callerName
                ))
            )
            savedText = updated.config.staticText ?? draftText
            draftText = savedText
            savedCallerName = updated.config.callerName ?? ""
            callerName = savedCallerName
            loadState = .ready(updated)
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}

@MainActor
struct NotesInputView: View {
    @EnvironmentObject var session: AppSession
    @Environment(\.dismiss) private var dismiss

    @State private var loaded = false
    @State private var hasInjectUserId = false
    @State private var usesPlainPresentation = false
    @State private var draftText = ""
    @State private var loadError: String?
    @State private var saveError: String?
    @State private var isSaving = false
    @State private var lastConfirmedText: String?

    var body: some View {
        Group {
            if let loadError {
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 34))
                            .foregroundStyle(.yellow)
                        Text("Couldn't load note")
                            .font(.title3.bold())
                        Text(loadError)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Button("Retry") {
                            Task { await load() }
                        }
                        .buttonStyle(IncomingButtonStyle(prominent: true))
                        .padding(.horizontal, 36)
                    }
                }
            } else if loaded {
                IncomingNotesView(
                    initialText: draftText,
                    showsSave: true,
                    onBack: { dismiss() },
                    onTextChanged: { draftText = $0 },
                    onSave: save,
                    onTripleTap: nil,
                    showsSystemShare: hasInjectUserId,
                    usesPlainPresentation: usesPlainPresentation
                )
                .disabled(isSaving)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if isSaving || lastConfirmedText == draftText {
                        Text(isSaving ? "Saving…" : "Note saved")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(Color.black)
                    }
                }
            } else {
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Loading note…")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await load() }
        .alert(
            "Couldn't Save",
            isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveError ?? "")
        }
    }

    private func load() async {
        loaded = false
        loadError = nil

        do {
            let data: PrimaryClipData = try await session.authenticated("/api/v1/clip-configs/primary")
            draftText = data.config.staticText ?? ""
            hasInjectUserId = !(data.config.injectUserId ?? "").isEmpty
            usesPlainPresentation = data.config.usesPlainPresentation == true
            loaded = true
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func save(_ text: String) {
        guard !isSaving else { return }
        guard text.utf16.count <= 500 else {
            saveError = "Use up to 500 characters for the force word or note."
            return
        }
        isSaving = true
        lastConfirmedText = nil
        Task {
            defer { isSaving = false }
            do {
                let data: PrimaryClipData = try await session.authenticated(
                    "/api/v1/clip-configs/primary",
                    method: "PATCH",
                    body: AnyEncodable(PrimaryClipUpdateRequest(staticText: text))
                )
                if (data.config.staticText ?? "") == text {
                    lastConfirmedText = text
                } else {
                    saveError = "The server did not confirm this note. Please try saving again."
                }
            } catch {
                saveError = error.localizedDescription
            }
        }
    }
}
