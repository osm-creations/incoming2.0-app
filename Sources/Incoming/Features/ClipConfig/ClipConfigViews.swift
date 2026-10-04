import SwiftUI
import UIKit

struct ClipConfigListView: View {
    @EnvironmentObject var session: AppSession
    @State private var configs: [ClipConfigSummary] = []
    @State private var showCreate = false
    @State private var error: String?

    var body: some View {
        List {
            ForEach(configs) { config in
                NavigationLink {
                    ClipConfigEditor(configId: config.id)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(config.name)
                            .font(.headline)
                        Text(config.mode.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button("Copy") {
                        UIPasteboard.general.string = config.invocationUrl
                    }
                    .tint(.blue)
                }
            }

            if let error {
                Text(error).foregroundStyle(.red)
            }
        }
        .scrollContentBackground(.hidden)
        .background(IncomingTheme.background)
        .navigationTitle("Notes Input")
        .toolbar {
            Button { showCreate = true } label: { Image(systemName: "plus") }
        }
        .sheet(isPresented: $showCreate) {
            CreateClipConfigView(onCreated: {
                showCreate = false
                Task { await load() }
            })
        }
        .task { await load() }
    }

    private func load() async {
        do {
            let data: ClipConfigsData = try await session.authenticated("/api/v1/clip-configs")
            configs = data.configs
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct CreateClipConfigView: View {
    @EnvironmentObject var session: AppSession
    @Environment(\.dismiss) var dismiss

    @State private var name = "App Clip 1"
    @State private var mode: ClipMode = .staticNote
    @State private var text = "Test"
    @State private var error: String?

    let onCreated: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)

                Picker("Mode", selection: $mode) {
                    ForEach(ClipMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }

                if mode != .menu {
                    Section("Initial note text") {
                        TextEditor(text: $text)
                            .frame(minHeight: 140)
                    }
                }

                if let error {
                    Text(error).foregroundStyle(.red)
                }
            }
            .navigationTitle("New App Clip")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task { await create() }
                    }
                }
            }
        }
    }

    private func create() async {
        do {
            let _: ClipConfigCreateData = try await session.authenticated(
                "/api/v1/clip-configs",
                method: "POST",
                body: AnyEncodable(
                    ClipConfigCreateRequest(
                        name: name,
                        mode: mode,
                        staticText: mode == .menu ? nil : text,
                        openOverflowInitially: false,
                        enabled: true
                    )
                )
            )
            onCreated()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct ClipConfigEditor: View {
    @EnvironmentObject var session: AppSession
    let configId: String

    @State private var detail: ClipConfigDetailData?
    @State private var draftText = ""
    @State private var savedText = ""
    @State private var newOption = ""
    @StateObject private var nfc = NFCWriterService()
    @State private var message: String?

    var body: some View {
        Form {
            if let detail {
                Section("\(detail.config.name) • \(detail.config.mode.title)") {
                    if detail.config.mode != .menu {
                        TextEditor(text: $draftText)
                            .frame(minHeight: 160)
                        if !savedText.isEmpty {
                            Text("Current saved text: \(savedText)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("This option shows your configured menu first. Once a menu option is chosen, the Notes screen remains editable.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Button("Save") {
                        Task { await save() }
                    }
                }

                if detail.config.mode == .menu {
                    Section("Menu options") {
                        ForEach(detail.options) { option in
                            Text(option.value)
                        }

                        HStack {
                            TextField("Add option", text: $newOption)
                            Button("Add") {
                                Task { await addOption() }
                            }
                            .disabled(newOption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }

                Section("Invocation") {
                    Button("Copy Link") {
                        UIPasteboard.general.string = detail.invocationUrl
                        message = "Link copied."
                    }

                    Button("Write NFC Tag") {
                        if let url = URL(string: detail.invocationUrl) {
                            nfc.write(url: url)
                        }
                    }

                    Text(detail.invocationUrl)
                        .font(.caption2)
                        .textSelection(.enabled)
                }
            } else {
                ProgressView()
            }

            if let message {
                Text(message).foregroundStyle(.secondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(IncomingTheme.background)
        .navigationTitle("Configure")
        .task { await load() }
        .alert("NFC", isPresented: Binding(get: { nfc.message != nil }, set: { if !$0 { nfc.message = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(nfc.message ?? "")
        }
    }

    private func load(preserveDraft: Bool = false) async {
        do {
            let loaded: ClipConfigDetailData = try await session.authenticated("/api/v1/clip-configs/\(configId)")
            detail = loaded
            let serverText = loaded.config.staticText ?? ""
            savedText = serverText
            if !preserveDraft || draftText.isEmpty {
                draftText = serverText
            }
        } catch {
            message = error.localizedDescription
        }
    }

    private func save() async {
        guard let detail else { return }
        do {
            let _: Updated = try await session.authenticated(
                "/api/v1/clip-configs/\(configId)",
                method: "PATCH",
                body: AnyEncodable(
                    ClipConfigPatchRequest(
                        name: nil,
                        mode: nil,
                        staticText: detail.config.mode == .menu ? nil : draftText,
                        openOverflowInitially: false,
                        enabled: nil
                    )
                )
            )
            savedText = draftText
            message = "Saved."
            await load(preserveDraft: true)
        } catch {
            message = error.localizedDescription
        }
    }

    private func addOption() async {
        do {
            let _: CreatedId = try await session.authenticated(
                "/api/v1/clip-configs/\(configId)/options",
                method: "POST",
                body: AnyEncodable(
                    ClipOptionCreateRequest(
                        value: newOption,
                        displayOrder: detail?.options.count ?? 0,
                        enabled: true
                    )
                )
            )
            newOption = ""
            await load(preserveDraft: true)
        } catch {
            message = error.localizedDescription
        }
    }
}

private struct Updated: Decodable { let updated: Bool }
private struct CreatedId: Decodable { let id: String }

struct NotesInputView: View {
    var body: some View {
        ClipConfigListView()
            .navigationTitle("Notes Input")
    }
}
